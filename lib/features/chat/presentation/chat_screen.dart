import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/app_providers.dart';
import '../../../app/branding/daram_logo.dart';
import '../../../app/design_system/daram_widgets.dart';
import '../../../app/theme/daram_colors.dart';
import '../../../core/domain/enums.dart';
import '../../../core/formatting/persian_formatting.dart';
import '../../../core/localization/fa_strings.dart';
import '../../../data/database/app_database.dart';
import '../../settings/domain/app_settings.dart';
import '../../sms/data/sms_inbox.dart';
import '../../sms/data/sms_review_repository.dart';
import '../../sms/presentation/sms_controller.dart';
import '../domain/chat_models.dart';
import '../domain/sms_chat_focus.dart';
import 'chat_controller.dart';
import 'chat_drawer.dart';
import 'pending_action_card.dart';
import 'report_card.dart';
import 'sms_chat_focus_controller.dart';
import 'sms_suggestion_cards.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scrollController = ScrollController();
  final _inputController = TextEditingController();
  final _focusNode = FocusNode();
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatControllerProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scheduleScroll({bool force = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final position = _scrollController.position;
      final nearBottom = position.maxScrollExtent - position.pixels < 240;
      if (!force && !nearBottom) return;
      _scrollController.animateTo(
        position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    final smsFocus = ref.read(smsChatFocusProvider);
    _inputController.clear();
    ref.read(smsChatFocusProvider.notifier).clear();
    setState(() {});
    if (!smsFocus.hasContent &&
        SmsInbox.supported &&
        RegExp(
          r'^(?=.*سرشماره)(?=.*(?:تنظیم|انتخاب|پیدا|نشون|نشان|اضافه|وصل|کدوم|کدام)).+$',
        ).hasMatch(text)) {
      final sms = ref.read(smsControllerProvider);
      _focusNode.unfocus();
      await context.push(sms.enabled ? '/sms/senders' : '/sms');
      return;
    }
    _focusNode.requestFocus();
    _scheduleScroll(force: true);
    await ref
        .read(chatControllerProvider.notifier)
        .send(text, smsFocus: smsFocus);
  }

  void _useSuggestion(String text) {
    _inputController.text = text;
    _inputController.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
    setState(() {});
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatControllerProvider);
    final settings =
        ref.watch(settingsControllerProvider).value ??
        const AppSettings.defaults();
    final colors = context.daram;
    final sms = SmsInbox.supported ? ref.watch(smsControllerProvider) : null;
    final smsCount = sms?.enabled == true
        ? ref.watch(smsDraftsProvider).value?.length ?? 0
        : 0;

    ref.listen<ChatUiState>(chatControllerProvider, (previous, next) {
      if (previous == null) return;
      final newMessage = next.messages.length != previous.messages.length;
      final newText =
          next.streamingText.length != previous.streamingText.length;
      if (newMessage || newText) {
        _lastMessageCount = next.messages.length;
        _scheduleScroll(force: newMessage);
      }
      if (previous.messages.isEmpty && next.messages.isNotEmpty) {
        _scheduleScroll(force: true);
      }
    });

    ref.listen(chatControllerProvider.select((s) => s.activeSession?.id), (
      previous,
      next,
    ) {
      if (previous != next) {
        ref.read(smsChatFocusProvider.notifier).clear();
      }
    });

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: colors.background,
      drawer: ChatHistoryDrawer(onClose: () => Navigator.of(context).pop()),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
            child: Row(
              children: [
                SoftIconButton(
                  icon: LucideIcons.menu,
                  tooltip: 'گفتگوها',
                  onTap: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                const SizedBox(width: 10),
                const DaramMark(size: 32),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        FaStrings.chatTitle,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        state.activeSession?.title ?? FaStrings.newChat,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: colors.textMuted),
                      ),
                    ],
                  ),
                ),
                if (SmsInbox.supported)
                  IconButton(
                    tooltip: 'بازبینی پیامک‌ها',
                    icon: Badge(
                      isLabelVisible: smsCount > 0,
                      label: Text(PersianDigits.toPersian('$smsCount')),
                      child: const Icon(LucideIcons.messageSquare),
                    ),
                    onPressed: () => context.push('/sms'),
                  ),
                SoftIconButton(
                  icon: LucideIcons.plus,
                  tooltip: FaStrings.newChat,
                  onTap: () async {
                    await ref
                        .read(chatControllerProvider.notifier)
                        .newSession();
                    if (!mounted) return;
                    _inputController.clear();
                    _scheduleScroll(force: true);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            if (!settings.isAIConfigured || state.configError != null)
              _ConfigBanner(
                message: state.configError ?? 'برای شروع گفتگو، کلید API و مدل دستیار را در تنظیمات وارد کن.',
                onTap: () => context.push('/settings/ai'),
              ),
            if (sms != null && sms.candidates.isNotEmpty)
              ListTile(
                leading: const Icon(LucideIcons.messageSquare),
                title: const Text(
                  'چند سرشمارهٔ بانکی هنوز به حساب‌ها وصل نشده‌اند.',
                ),
                trailing: const Icon(LucideIcons.chevronLeft),
                onTap: () => context.push('/sms/senders'),
              ),
            if (state.error != null)
              _ErrorBanner(
                message: state.error!,
                onDismiss: () =>
                    ref.read(chatControllerProvider.notifier).dismissError(),
              ),
            Expanded(
              child: _lastMessageCount == 0 && state.messages.isEmpty
                  ? (state.loading
                        ? const Center(child: CircularProgressIndicator())
                        : _EmptyChat(onSuggestion: _useSuggestion))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount:
                          state.messages.length + (state.streaming ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= state.messages.length) {
                          return _StreamingMessage(
                            text: state.streamingText,
                            onStop: () => ref
                                .read(chatControllerProvider.notifier)
                                .stop(),
                          );
                        }
                        final message = state.messages[index];
                        final isLast = index == state.messages.length - 1;
                        return _MessageView(
                          message: message,
                          actions: state.actionsFor(message.id),
                          isLast: isLast,
                          onCopy: () async {
                            await Clipboard.setData(
                              ClipboardData(text: message.content),
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                const SnackBar(content: Text('پیام کپی شد.')),
                              );
                          },
                          onRegenerate:
                              isLast && !state.streaming && state.canRegenerate
                              ? () => ref
                                    .read(chatControllerProvider.notifier)
                                    .regenerate()
                              : null,
                          onUndo: (operationId) => ref
                              .read(chatControllerProvider.notifier)
                              .undo(operationId),
                          onConfirmAll: () => ref
                              .read(chatControllerProvider.notifier)
                              .confirmAll(message.id),
                        );
                      },
                    ),
            ),
            _Composer(
              controller: _inputController,
              focusNode: _focusNode,
              streaming: state.streaming,
              onSend: _send,
              onStop: () => ref.read(chatControllerProvider.notifier).stop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfigBanner extends StatelessWidget {
  const _ConfigBanner({required this.message, required this.onTap});

  final String message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.keyRound, size: 18, color: colors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              backgroundColor: colors.accent,
            ),
            child: const Text('تنظیم'),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0);
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 6),
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
      decoration: BoxDecoration(
        color: colors.expense.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.expense.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.circleAlert, size: 16, color: colors.expense),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.expense),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onDismiss,
            icon: Icon(LucideIcons.x, size: 16, color: colors.expense),
          ),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.onSuggestion});

  final ValueChanged<String> onSuggestion;

  static const _examples = [
    'امروز ۲۵۰ هزار تومان ناهار خوردم',
    'دیروز ۳ میلیون تومان حقوق گرفتم',
    '۵ میلیون تومان از حساب ملت به بلو بانک انتقال دادم',
    'یه وام ۳۰ میلیونی گرفتم که باید تو ۳ قسط پرداخت کنم',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        colors.accent.withValues(alpha: 0.18),
                        colors.accent.withValues(alpha: 0),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const DaramMark(size: 62),
                ),
              )
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(begin: const Offset(0.9, 0.9)),
          const SizedBox(height: 16),
          Text(
            FaStrings.chatEmptyTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            FaStrings.chatEmptyMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: colors.textSecondary, height: 1.8),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _QuickAction(
                label: FaStrings.quickExpense,
                icon: LucideIcons.arrowUpRight,
                onTap: () => onSuggestion('امروز ۲۵۰ هزار تومان '),
              ),
              _QuickAction(
                label: FaStrings.quickIncome,
                icon: LucideIcons.arrowDownLeft,
                onTap: () => onSuggestion('امروز '),
              ),
              _QuickAction(
                label: FaStrings.quickAddAccount,
                icon: LucideIcons.landmark,
                onTap: () => onSuggestion('یه حساب بلو بانک دارم، '),
              ),
              _QuickAction(
                label: FaStrings.quickTodayReport,
                icon: LucideIcons.chartPie,
                onTap: () => onSuggestion('گزارش امروز رو بده'),
              ),
              _QuickAction(
                label: FaStrings.quickMonthReport,
                icon: LucideIcons.calendarDays,
                onTap: () => onSuggestion('گزارش این ماه رو بده'),
              ),
              _QuickAction(
                label: FaStrings.quickLoans,
                icon: LucideIcons.banknote,
                onTap: () => onSuggestion('وضعیت وام‌ها چطوره؟'),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              Text(
                'مثال‌ها',
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: colors.textMuted),
              ),
              const SizedBox(width: 8),
              Expanded(child: Container(height: 1, color: colors.divider)),
            ],
          ),
          const SizedBox(height: 10),
          for (final example in _examples)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => onSuggestion(example),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.sparkles,
                        size: 15,
                        color: colors.accent,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          example,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      Icon(
                        LucideIcons.arrowLeft,
                        size: 14,
                        color: colors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'پیش از ثبت هر تراکنش از تو تأیید می‌گیرم.',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: colors.textMuted),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 350.ms),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    return Material(
      color: colors.surfaceMuted,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: colors.textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.message,
    required this.actions,
    required this.isLast,
    required this.onCopy,
    required this.onRegenerate,
    required this.onUndo,
    required this.onConfirmAll,
  });

  final ChatMessage message;
  final List<PendingAction> actions;
  final bool isLast;
  final VoidCallback onCopy;
  final VoidCallback? onRegenerate;
  final ValueChanged<String> onUndo;
  final VoidCallback onConfirmAll;

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return _UserBubble(message: message);
    }
    if (message.type == ChatMessageType.confirmation) {
      return _ConfirmationMessage(message: message, onUndo: onUndo);
    }
    if (message.type == ChatMessageType.info) {
      return _InfoMessage(message: message);
    }
    if (message.type == ChatMessageType.error) {
      return _AssistantBubble(
        message: message,
        actions: const [],
        onCopy: onCopy,
        onRegenerate: onRegenerate,
        isError: true,
        onUndo: onUndo,
        onConfirmAll: onConfirmAll,
        isLast: isLast,
      );
    }
    return _AssistantBubble(
      message: message,
      actions: actions,
      onCopy: onCopy,
      onRegenerate: onRegenerate,
      onUndo: onUndo,
      onConfirmAll: onConfirmAll,
      isLast: isLast,
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        margin: const EdgeInsets.only(top: 10, bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        decoration: BoxDecoration(
          color: colors.chatUser,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(6),
          ),
          border: Border.all(color: colors.accent.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.metadata['smsFocusLabel'] case final label?)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      message.metadata['smsReplyTo'] != null
                          ? LucideIcons.reply
                          : LucideIcons.listChecks,
                      size: 12,
                      color: colors.accent,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '$label',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: colors.accent),
                      ),
                    ),
                  ],
                ),
              ),
            SelectableText(
              message.content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.isDark ? Colors.white : colors.textPrimary,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).slideX(begin: 0.04, end: 0);
  }
}

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({
    required this.message,
    required this.actions,
    required this.onCopy,
    required this.onRegenerate,
    required this.onUndo,
    required this.onConfirmAll,
    required this.isLast,
    this.isError = false,
  });

  final ChatMessage message;
  final List<PendingAction> actions;
  final VoidCallback onCopy;
  final VoidCallback? onRegenerate;
  final ValueChanged<String> onUndo;
  final VoidCallback onConfirmAll;
  final bool isLast;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final reports = _reportsOf(message);
    final smsIds = _smsIdsOf(message);
    final pending = actions.where((action) => action.isPending).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DaramMark(size: 26),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isError
                        ? colors.expense.withValues(alpha: 0.07)
                        : colors.chatAssistant,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    border: Border.all(
                      color: isError
                          ? colors.expense.withValues(alpha: 0.2)
                          : colors.border,
                    ),
                  ),
                  child: MarkdownBody(
                    data: message.content,
                    selectable: false,
                    styleSheet: _markdownStyle(context, isError),
                  ),
                ),
                if (pending.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 10, left: 2, right: 2),
                    child: Row(
                      children: [
                        Text(
                          'این پیام ${PersianDigits.toPersian('${pending.length}')} پیش‌نویس دارد',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colors.textMuted),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: onConfirmAll,
                          child: const Text('تأیید همه'),
                        ),
                      ],
                    ),
                  ),
                for (final action in actions) PendingActionCard(action: action),
                if (smsIds.isNotEmpty) SmsSuggestionCards(ids: smsIds),
                for (final report in reports) ChatReportCard(report: report),
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 4),
                  child: Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(
                          minWidth: 30,
                          minHeight: 30,
                        ),
                        onPressed: onCopy,
                        icon: Icon(
                          LucideIcons.copy,
                          size: 14,
                          color: colors.textMuted,
                        ),
                        tooltip: 'کپی',
                      ),
                      if (onRegenerate != null)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(
                            minWidth: 30,
                            minHeight: 30,
                          ),
                          onPressed: onRegenerate,
                          icon: Icon(
                            LucideIcons.rotateCcw,
                            size: 14,
                            color: colors.textMuted,
                          ),
                          tooltip: 'تولید دوباره',
                        ),
                      if (isLast && message.type == ChatMessageType.error)
                        TextButton.icon(
                          onPressed: onRegenerate,
                          icon: const Icon(LucideIcons.refreshCw, size: 14),
                          label: const Text('تلاش دوباره'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 280.ms);
  }

  List<String> _smsIdsOf(ChatMessage message) {
    final raw = message.metadata['smsSuggestionIds'];
    if (raw is! List) return const <String>[];
    return raw.map((item) => '$item').where((id) => id.isNotEmpty).toList();
  }

  List<ReportCardData> _reportsOf(ChatMessage message) {
    final raw = message.metadata['reports'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (item) => ReportCardData.fromJson(
            item.map((key, value) => MapEntry('$key', value)),
          ),
        )
        .toList();
  }

  MarkdownStyleSheet _markdownStyle(BuildContext context, bool isError) {
    final colors = context.daram;
    final base = Theme.of(context).textTheme.bodyMedium!;
    return MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      p: base.copyWith(
        color: isError ? colors.expense : colors.textPrimary,
        height: 1.85,
      ),
      h1: Theme.of(context).textTheme.titleLarge,
      h2: Theme.of(context).textTheme.titleMedium,
      h3: Theme.of(context).textTheme.titleSmall,
      strong: base.copyWith(
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
      ),
      em: base.copyWith(fontStyle: FontStyle.italic),
      blockSpacing: 8,
      listIndent: 20,
      listBullet: base.copyWith(color: colors.textSecondary),
      code: base.copyWith(
        fontFamily: 'monospace',
        backgroundColor: colors.surfaceMuted,
        color: colors.textPrimary,
      ),
      blockquoteDecoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border(right: BorderSide(color: colors.accent, width: 3)),
      ),
      blockquotePadding: const EdgeInsets.all(10),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.divider)),
      ),
    );
  }
}

class _ConfirmationMessage extends StatelessWidget {
  const _ConfirmationMessage({required this.message, required this.onUndo});

  final ChatMessage message;
  final ValueChanged<String> onUndo;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final operationId = message.metadata['operationId'];
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.income.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.income.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: colors.income.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.check, size: 14, color: colors.income),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message.content,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.textPrimary),
            ),
          ),
          if (operationId is String)
            TextButton(
              onPressed: () => onUndo(operationId),
              child: const Text('برگرداندن'),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 260.ms);
  }
}

class _InfoMessage extends StatelessWidget {
  const _InfoMessage({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: colors.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.info, size: 14, color: colors.textMuted),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                message.content,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreamingMessage extends StatelessWidget {
  const _StreamingMessage({required this.text, required this.onStop});

  final String text;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DaramMark(size: 26),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                color: colors.chatAssistant,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(color: colors.border),
              ),
              child: text.isEmpty
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _TypingDots(color: colors.textMuted),
                        const SizedBox(width: 10),
                        Text(
                          FaStrings.thinking,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.textMuted),
                        ),
                      ],
                    )
                  : MarkdownBody(
                      data: text,
                      selectable: false,
                      styleSheet:
                          MarkdownStyleSheet.fromTheme(Theme.of(context))
                              .copyWith(
                                p: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(height: 1.85),
                              ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots({required this.color});

  final Color color;

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Opacity(
                  opacity: 0.3 + 0.7 * _wave(i),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  double _wave(int index) {
    final phase = (_controller.value + index * 0.18) % 1;
    if (phase < 0.5) return phase * 2;
    return (1 - phase) * 2;
  }
}

class _Composer extends ConsumerWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.streaming,
    required this.onSend,
    required this.onStop,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool streaming;
  final VoidCallback onSend;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.daram;
    final focus = ref.watch(smsChatFocusProvider);
    ref.listen<SmsChatFocus>(smsChatFocusProvider, (previous, next) {
      // Replying is a one-item action, so open the keyboard immediately.
      // Group selection stays keyboard-free until the user taps the composer,
      // otherwise the keyboard would cover the rows they are still selecting.
      if (!(previous?.hasReply ?? false) && next.hasReply) {
        focusNode.requestFocus();
      }
    });
    final hint = focus.hasReply
        ? 'پاسخ به این پیشنهاد را بنویس…'
        : focus.hasSelection
        ? 'دستور برای موارد انتخاب‌شده…'
        : FaStrings.chatHint;

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.divider)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (focus.hasContent) _SmsFocusBar(focus: focus),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: colors.surfaceMuted,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: colors.border),
                    ),
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      minLines: 1,
                      maxLines: 5,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      textAlignVertical: TextAlignVertical.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintText: hint,
                        hintStyle: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: colors.textMuted),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, child) {
                    final enabled = value.text.trim().isNotEmpty;
                    if (streaming) {
                      return _CircleButton(
                        icon: LucideIcons.square,
                        onTap: onStop,
                        background: colors.surfaceElevated,
                        foreground: colors.expense,
                        tooltip: FaStrings.stop,
                      );
                    }
                    return _CircleButton(
                      icon: LucideIcons.arrowUp,
                      onTap: enabled ? onSend : null,
                      gradient: enabled ? colors.brandGradient : null,
                      background: colors.surfaceMuted,
                      foreground: enabled ? colors.onAccent : colors.textMuted,
                      tooltip: FaStrings.send,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SmsFocusBar extends ConsumerWidget {
  const _SmsFocusBar({required this.focus});

  final SmsChatFocus focus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.daram;
    final text = Theme.of(context).textTheme;
    final format = DaramFormat.of(context);
    final replyRow = focus.replyToId == null
        ? null
        : ref.watch(smsSuggestionProvider(focus.replyToId!)).value;
    final title = focus.hasReply
        ? 'پاسخ به پیشنهاد پیامکی'
        : '${PersianDigits.toPersian('${focus.selectedIds.length}')} پیشنهاد انتخاب‌شده';
    final subtitle = focus.hasReply
        ? _replySummary(replyRow, format)
        : 'دستور را بنویس؛ دستیار روی همین موارد اجرا می‌کند.';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(
            focus.hasReply ? LucideIcons.reply : LucideIcons.listChecks,
            size: 15,
            color: colors.accent,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: text.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelSmall?.copyWith(color: colors.textMuted),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => ref.read(smsChatFocusProvider.notifier).clear(),
            tooltip: 'پاک کردن',
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
            icon: Icon(LucideIcons.x, size: 15, color: colors.textMuted),
          ),
        ],
      ),
    );
  }

  String? _replySummary(SmsSuggestionRow? row, DaramFormat format) {
    if (row == null) return 'پیشنهاد پیامکی';
    final draft = SmsReviewRepository.draftOf(row);
    final title = draft.description?.trim();
    final amount = draft.amountRial.isZero
        ? null
        : format.money.format(draft.amountRial);
    return [
      if (title != null && title.isNotEmpty) title,
      ?amount,
      if (row.status == 'pending') 'در انتظار تأیید',
    ].join(' · ');
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    required this.foreground,
    this.background,
    this.gradient,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color foreground;
  final Color? background;
  final Gradient? gradient;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: gradient == null ? background : null,
      shape: const CircleBorder(),
      child: Ink(
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: gradient),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, size: 20, color: foreground),
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
