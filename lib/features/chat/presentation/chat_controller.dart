import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../../../core/domain/enums.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/formatting/persian_formatting.dart';
import '../../../core/money/currency.dart';
import '../../../data/database/app_database.dart';
import '../../ai/data/ai_chat_service.dart';
import '../../ai/data/ai_log_store.dart';
import '../../ai/data/prompt_builder.dart';
import '../../ai/domain/ai_log.dart';
import '../../settings/domain/app_settings.dart';
import '../../sms/data/sms_review_repository.dart';
import '../data/chat_repository.dart';
import '../data/sms_focus_prompt.dart';
import '../domain/chat_models.dart';
import '../domain/drafts.dart';
import '../domain/sms_chat_focus.dart';

/// UI state for the conversation screen.
class ChatUiState {
  const ChatUiState({
    this.sessions = const [],
    this.activeSession,
    this.messages = const [],
    this.pendingByMessage = const {},
    this.loading = false,
    this.streaming = false,
    this.streamingText = '',
    this.searchQuery = '',
    this.error,
    this.configError,
  });

  final List<ChatSession> sessions;
  final ChatSession? activeSession;
  final List<ChatMessage> messages;
  final Map<String, List<PendingAction>> pendingByMessage;
  final bool loading;
  final bool streaming;
  final String streamingText;
  final String searchQuery;
  final String? error;
  final String? configError;

  List<PendingAction> actionsFor(String messageId) =>
      pendingByMessage[messageId] ?? const [];

  bool get hasPendingActions => pendingByMessage.values.any(
    (actions) => actions.any((action) => action.isPending),
  );

  bool get canRegenerate {
    final lastUser = messages.lastIndexWhere((message) => message.isUser);
    return lastUser >= 0 &&
        messages
            .skip(lastUser + 1)
            .every(
              (message) =>
                  message.type != ChatMessageType.confirmation &&
                  actionsFor(message.id).every(
                    (action) => action.status != PendingActionStatus.confirmed,
                  ),
            );
  }

  List<ChatSession> get filteredSessions {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return sessions;
    return sessions
        .where(
          (session) =>
              session.title.toLowerCase().contains(query) ||
              (session.preview ?? '').toLowerCase().contains(query),
        )
        .toList();
  }

  ChatUiState copyWith({
    List<ChatSession>? sessions,
    ChatSession? activeSession,
    List<ChatMessage>? messages,
    Map<String, List<PendingAction>>? pendingByMessage,
    bool? loading,
    bool? streaming,
    String? streamingText,
    String? searchQuery,
    String? error,
    String? configError,
    bool clearError = false,
    bool clearConfigError = false,
    bool clearActiveSession = false,
  }) {
    return ChatUiState(
      sessions: sessions ?? this.sessions,
      activeSession: clearActiveSession
          ? null
          : (activeSession ?? this.activeSession),
      messages: messages ?? this.messages,
      pendingByMessage: pendingByMessage ?? this.pendingByMessage,
      loading: loading ?? this.loading,
      streaming: streaming ?? this.streaming,
      streamingText: streamingText ?? this.streamingText,
      searchQuery: searchQuery ?? this.searchQuery,
      error: clearError ? null : (error ?? this.error),
      configError: clearConfigError ? null : (configError ?? this.configError),
    );
  }
}

final chatControllerProvider = NotifierProvider<ChatController, ChatUiState>(
  ChatController.new,
);

/// Orchestrates persistence, the AI run loop and the confirmation workflow.
class ChatController extends Notifier<ChatUiState> {
  StreamSubscription<ChatRunEvent>? _subscription;
  final StringBuffer _buffer = StringBuffer();
  bool _initialized = false;
  bool _finishHandled = false;
  String? _activeRunSessionId;
  bool _stopped = false;

  ChatRepository get _chat => ref.read(chatRepositoryProvider);

  AILogStore get _logs => ref.read(aiLogStoreProvider);

  @override
  ChatUiState build() {
    ref.onDispose(() {
      _subscription?.cancel();
    });
    return const ChatUiState();
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    state = state.copyWith(loading: true);
    try {
      var sessions = await _chat.listSessions();
      ChatSession session;
      if (sessions.isEmpty) {
        session = await _chat.createSession();
        sessions = await _chat.listSessions();
      } else {
        session = sessions.first;
      }
      state = state.copyWith(
        sessions: sessions,
        activeSession: session,
        loading: false,
        clearError: true,
      );
      await _loadSession(session.id);
    } on Object {
      state = state.copyWith(
        loading: false,
        error: 'بارگذاری گفتگوها ممکن نشد.',
      );
    }
  }

  Future<void> refresh() async {
    final session = state.activeSession;
    await _reloadSessions();
    if (session != null) await _loadSession(session.id);
  }

  Future<void> selectSession(String id) async {
    await _loadSession(id);
  }

  Future<void> newSession() async {
    try {
      final session = await _chat.createSession();
      await _reloadSessions();
      await _loadSession(session.id);
    } on Object {
      state = state.copyWith(error: 'ساخت گفتگوی جدید ممکن نشد.');
    }
  }

  Future<void> renameSession(String id, String title) async {
    try {
      await _chat.renameSession(id, title);
      await _reloadSessions();
      if (state.activeSession?.id == id) {
        state = state.copyWith(activeSession: await _chat.findSession(id));
      }
    } on AppException catch (error) {
      state = state.copyWith(error: error.message);
    }
  }

  Future<void> deleteSession(String id) async {
    try {
      await _chat.deleteSession(id);
      var sessions = await _chat.listSessions();
      if (sessions.isEmpty) {
        await _chat.createSession();
        sessions = await _chat.listSessions();
      }
      state = state.copyWith(
        sessions: sessions,
        activeSession: sessions.first,
        messages: const [],
        pendingByMessage: const {},
      );
      await _loadSession(sessions.first.id);
    } on Object {
      state = state.copyWith(error: 'حذف گفتگو ممکن نشد.');
    }
  }

  void setSearchQuery(String query) =>
      state = state.copyWith(searchQuery: query);

  void dismissError() => state = state.copyWith(clearError: true);

  void dismissConfigError() => state = state.copyWith(clearConfigError: true);

  Future<void> send(
    String text, {
    SmsChatFocus smsFocus = const SmsChatFocus(),
  }) async {
    final content = text.trim();
    if (content.isEmpty || state.streaming) return;
    final session = state.activeSession ?? await _ensureSession();
    if (session == null) return;

    final previousMessages = List<ChatMessage>.of(state.messages);
    try {
      final smsRows = await _smsFocusRows(smsFocus);
      final smsLabel = _smsFocusLabel(smsFocus, smsRows);
      final userMessage = await _chat.addMessage(
        sessionId: session.id,
        role: ChatRole.user,
        content: content,
        type: ChatMessageType.text,
        metadata: {
          'smsFocusLabel': ?smsLabel,
          'smsReplyTo': ?smsFocus.replyToId,
          if (smsFocus.hasSelection)
            'smsSelection': smsFocus.selectedIds.toList(),
        },
      );
      state = state.copyWith(
        messages: [...previousMessages, userMessage],
        clearError: true,
      );

      // Auto-title the conversation from its first user message.
      final isDefaultTitle = session.title == ChatRepository.defaultTitle;
      if (isDefaultTitle &&
          previousMessages.where((message) => message.isUser).isEmpty) {
        final title = content.replaceAll('\n', ' ').trim();
        await _chat.renameSession(
          session.id,
          title.length > 42 ? '${title.substring(0, 42)}…' : title,
        );
        await _reloadSessions();
      }

      await _run(
        userText: content,
        history: previousMessages,
        sessionId: session.id,
        smsFocus: smsFocus,
        smsRows: smsRows,
      );
    } on Object {
      state = state.copyWith(error: 'ثبت پیام ممکن نشد.');
    }
  }

  /// Regenerates the last assistant answer using the same user message.
  Future<void> regenerate() async {
    if (state.streaming || !state.canRegenerate) return;
    final messages = state.messages;
    final lastUserIndex = messages.lastIndexWhere((message) => message.isUser);
    if (lastUserIndex == -1) return;
    final userMessage = messages[lastUserIndex];
    final session = state.activeSession;
    if (session == null) return;

    try {
      for (final message in messages.skip(lastUserIndex + 1)) {
        await _chat.deleteMessage(message.id);
      }
      await _loadSession(session.id);
      await _run(
        userText: userMessage.content,
        history: messages.take(lastUserIndex).toList(),
        sessionId: session.id,
      );
    } on Object {
      state = state.copyWith(error: 'تولید دوباره پاسخ ممکن نشد.');
    }
  }

  Future<void> stop() async {
    if (!state.streaming) return;
    _stopped = true;
    _finishHandled = true;
    await _subscription?.cancel();
    _subscription = null;
    final sessionId = _activeRunSessionId;
    final partial = _buffer.toString().trim();
    if (sessionId != null && partial.isNotEmpty) {
      await _chat.addMessage(
        sessionId: sessionId,
        role: ChatRole.assistant,
        content: '$partial\n\n_(پاسخ متوقف شد.)_',
        type: ChatMessageType.text,
      );
    }
    state = state.copyWith(streaming: false, streamingText: '');
    if (sessionId != null) await _loadSession(sessionId);
  }

  Future<void> _run({
    required String userText,
    required List<ChatMessage> history,
    required String sessionId,
    SmsChatFocus smsFocus = const SmsChatFocus(),
    List<SmsSuggestionRow> smsRows = const [],
  }) async {
    _buffer.clear();
    _finishHandled = false;
    _stopped = false;
    _activeRunSessionId = sessionId;
    state = state.copyWith(
      streaming: true,
      streamingText: '',
      error: null,
      clearError: true,
      configError: null,
      clearConfigError: true,
    );

    final settings = _settings;
    if (!settings.isAIConfigured) {
      _logs.error(
        'گفتگو آغاز نشد: دستیار تنظیم نشده است',
        area: AILogArea.chat,
        provider: settings.aiConfig.provider.label,
        model: settings.aiConfig.model,
      );
      state = state.copyWith(
        streaming: false,
        configError:
            'برای گفتگو با دستیار، ابتدا کلید API را در تنظیمات وارد کن.',
      );
      return;
    }

    try {
      final promptBuilder = await ref.read(promptBuilderProvider.future);
      final toolRegistry = await ref.read(toolRegistryProvider.future);
      final service = await ref.read(aiChatServiceProvider.future);
      final accounts = await ref
          .read(accountRepositoryProvider)
          .listWithBalances();
      final categories = await ref.read(categoryRepositoryProvider).list();
      final loans = await ref.read(loanRepositoryProvider).list();
      final prompt = promptBuilder.build(
        PromptContext(
          now: DateTime.now(),
          currency: settings.currencyUnit,
          accounts: accounts,
          categories: categories,
          loans: loans,
          tools: toolRegistry.definitions,
          toolMode: settings.aiConfig.toolMode,
        ),
      );
      final focusPrompt = buildSmsFocusPrompt(
        focus: smsFocus,
        rows: smsRows,
        accountIds: {for (final item in accounts) item.account.id},
        categoryIds: {for (final category in categories) category.id},
        currency: settings.currencyUnit,
      );
      final systemPrompt = focusPrompt.isEmpty
          ? prompt
          : '$prompt\n\n$focusPrompt';

      _subscription = service
          .run(
            config: settings.aiConfig,
            systemPrompt: systemPrompt,
            history: history,
            userMessage: userText,
            sessionId: sessionId,
            defaultCurrency: settings.currencyUnit,
          )
          .listen(
            (event) {
              switch (event) {
                case ChatRunText(:final text):
                  _buffer.write(text);
                  state = state.copyWith(streamingText: _buffer.toString());
                case ChatRunCompleted():
                  unawaited(_completeRun(event, sessionId));
                case ChatRunFailed(:final message):
                  unawaited(_failRun(message, sessionId));
              }
            },
            onError: (Object error) {
              _logs.error(
                'جریان پاسخ دستیار قطع شد',
                area: AILogArea.chat,
                provider: settings.aiConfig.provider.label,
                model: settings.aiConfig.model,
                detail: error.toString(),
              );
              unawaited(_failRun('ارتباط با دستیار قطع شد.', sessionId));
            },
            onDone: () {
              if (!_finishHandled && !_stopped) {
                unawaited(
                  _completeRun(
                    ChatRunCompleted(
                      text: _buffer.toString(),
                      actions: const [],
                      reports: const [],
                    ),
                    sessionId,
                  ),
                );
              }
            },
            cancelOnError: false,
          );
    } on Object catch (error) {
      _logs.error(
        'آماده‌سازی دستیار ناموفق بود',
        area: AILogArea.chat,
        provider: settings.aiConfig.provider.label,
        model: settings.aiConfig.model,
        detail: error.toString(),
      );
      await _failRun('آماده‌سازی دستیار ممکن نشد.', sessionId);
    }
  }

  Future<void> _completeRun(ChatRunCompleted event, String sessionId) async {
    if (_finishHandled) return;
    _finishHandled = true;

    final text = event.text.trim();
    final actions = event.actions;
    final reports = event.reports;
    final smsIds = event.smsSuggestionIds;
    final content = text.isNotEmpty
        ? text
        : actions.isNotEmpty
        ? 'پیش‌نویس آماده شد؛ لطفاً بررسی و تأیید کن.'
        : reports.isNotEmpty
        ? 'گزارش آماده شد.'
        : smsIds.isNotEmpty
        ? 'این پیشنهادهای پیامکی آمادهٔ بازبینی‌اند.'
        : 'پاسخی دریافت نشد. یک بار دیگر تلاش کن.';

    try {
      await _chat.addAssistantReply(
        sessionId: sessionId,
        actions: actions,
        content: content,
        type: actions.isNotEmpty
            ? ChatMessageType.draft
            : reports.isNotEmpty
            ? ChatMessageType.report
            : ChatMessageType.text,
        metadata: {
          if (actions.isNotEmpty)
            'pendingActionIds': actions.map((action) => action.id).toList(),
          if (reports.isNotEmpty) 'reports': reports,
          if (smsIds.isNotEmpty) 'smsSuggestionIds': smsIds,
        },
      );
      state = state.copyWith(streaming: false, streamingText: '');
      await _loadSession(sessionId);
      await _reloadSessions();
    } on Object catch (error) {
      _logs.error(
        'ذخیره پاسخ دستیار ناموفق بود',
        area: AILogArea.chat,
        provider: _settings.aiConfig.provider.label,
        model: _settings.aiConfig.model,
        detail: error.toString(),
      );
      state = state.copyWith(
        streaming: false,
        streamingText: '',
        error: 'ذخیره پاسخ دستیار ممکن نشد.',
      );
    }
  }

  Future<void> _failRun(String message, String sessionId) async {
    if (_finishHandled) return;
    _finishHandled = true;
    _logs.error(
      'اجرای دستیار ناموفق بود',
      area: AILogArea.chat,
      provider: _settings.aiConfig.provider.label,
      model: _settings.aiConfig.model,
      detail: message,
    );
    try {
      await _chat.addMessage(
        sessionId: sessionId,
        role: ChatRole.assistant,
        content: message,
        type: ChatMessageType.error,
        metadata: const {'retryable': true},
      );
      state = state.copyWith(
        streaming: false,
        streamingText: '',
        error: message,
      );
      await _loadSession(sessionId);
    } on Object {
      state = state.copyWith(
        streaming: false,
        streamingText: '',
        error: message,
      );
    }
  }

  Future<String> confirmAction(
    String actionId, {
    Map<String, Object?>? payload,
  }) async {
    try {
      final operationId = await ref
          .read(confirmationServiceProvider)
          .confirm(actionId, payload: payload);
      final action = await _chat.findPendingAction(actionId);
      if (action != null) {
        final draft = FinancialDraft.fromPendingAction(action);
        final summary = draft?.title ?? 'عملیات مالی';
        await _chat.addMessage(
          sessionId: action.sessionId,
          role: ChatRole.assistant,
          content: 'ثبت شد: $summary',
          type: ChatMessageType.confirmation,
          metadata: {'operationId': operationId, 'summary': summary},
        );
      }
      await _refreshActive();
      return operationId;
    } on AppException catch (error) {
      state = state.copyWith(error: error.message);
      await _refreshActive();
      rethrow;
    }
  }

  /// Persists an edited draft without executing it, so the user can still
  /// explicitly approve the final version.
  Future<void> updateDraft(
    String actionId,
    Map<String, Object?> payload,
  ) async {
    final action = await _chat.findPendingAction(actionId);
    if (action == null || !action.isPending) return;
    await _chat.updatePendingAction(
      action.copyWith(payload: payload, errorMessage: null),
    );
    await _refreshActive();
  }

  Future<void> confirmAll(String messageId) async {
    final actions = state
        .actionsFor(messageId)
        .where((action) => action.isPending)
        .toList();
    for (final action in actions) {
      try {
        await confirmAction(action.id);
      } on AppException {
        break;
      }
    }
  }

  Future<void> rejectAction(String actionId) async {
    try {
      await ref.read(confirmationServiceProvider).reject(actionId);
      await _refreshActive();
    } on AppException catch (error) {
      state = state.copyWith(error: error.message);
    }
  }

  Future<void> undo(String operationId) async {
    try {
      await ref.read(undoServiceProvider).undo(operationId);
      final sessionId = state.activeSession?.id;
      if (sessionId != null) {
        await _chat.addMessage(
          sessionId: sessionId,
          role: ChatRole.assistant,
          content: 'عملیات برگشت داده شد و موجودی‌ها به‌روزرسانی شدند.',
          type: ChatMessageType.info,
        );
      }
      await _refreshActive();
    } on AppException catch (error) {
      state = state.copyWith(error: error.message);
    }
  }

  Future<List<SmsSuggestionRow>> _smsFocusRows(SmsChatFocus focus) async {
    if (!focus.hasContent) return const [];
    final ids = <String>{
      ...focus.selectedIds,
      if (focus.replyToId != null) focus.replyToId!,
    };
    final repository = SmsReviewRepository(
      ref.read(databaseProvider),
      ref.read(transactionRepositoryProvider),
    );
    final rows = <SmsSuggestionRow>[];
    for (final id in ids) {
      final row = await repository.find(id);
      if (row != null) rows.add(row);
    }
    return rows;
  }

  String? _smsFocusLabel(SmsChatFocus focus, List<SmsSuggestionRow> rows) {
    if (!focus.hasContent) return null;
    if (!focus.hasReply) {
      return '${PersianDigits.toPersian('${focus.selectedIds.length}')} پیشنهاد انتخاب‌شده';
    }
    if (rows.isEmpty) return 'پاسخ به پیشنهاد پیامکی';
    final draft = SmsReviewRepository.draftOf(rows.first);
    final formatter = MoneyFormatter(unit: _settings.currencyUnit);
    final title = draft.description?.trim();
    final amount = draft.amountRial.isZero
        ? null
        : formatter.format(draft.amountRial);
    return [
      'پاسخ به پیشنهاد',
      if (title != null && title.isNotEmpty) title,
      ?amount,
    ].join(' · ');
  }

  AppSettings get _settings =>
      ref.read(settingsControllerProvider).value ??
      const AppSettings.defaults();

  CurrencyUnit get defaultCurrency => _settings.currencyUnit;

  Future<ChatSession?> _ensureSession() async {
    final existing = state.activeSession;
    if (existing != null) return existing;
    final session = await _chat.createSession();
    await _reloadSessions();
    await _loadSession(session.id);
    return session;
  }

  Future<void> _reloadSessions() async {
    final sessions = await _chat.listSessions();
    state = state.copyWith(
      sessions: sessions,
      activeSession: state.activeSession == null
          ? null
          : sessions.firstWhere(
              (session) => session.id == state.activeSession!.id,
              orElse: () =>
                  sessions.isEmpty ? state.activeSession! : sessions.first,
            ),
    );
  }

  Future<void> _loadSession(String sessionId) async {
    state = state.copyWith(loading: true);
    try {
      final session = await _chat.findSession(sessionId);
      final messages = await _chat.messages(sessionId);
      final actions = await _chat.pendingActionsForSession(sessionId);
      final grouped = <String, List<PendingAction>>{};
      for (final action in actions) {
        final messageId = action.messageId;
        if (messageId == null) continue;
        grouped.putIfAbsent(messageId, () => []).add(action);
      }
      state = state.copyWith(
        activeSession: session,
        messages: messages,
        pendingByMessage: grouped,
        loading: false,
      );
    } on Object {
      state = state.copyWith(loading: false, error: 'بارگذاری گفتگو ممکن نشد.');
    }
  }

  Future<void> _refreshActive() async {
    final sessionId = state.activeSession?.id;
    await _reloadSessions();
    if (sessionId != null) await _loadSession(sessionId);
  }
}
