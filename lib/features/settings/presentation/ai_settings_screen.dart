import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/app_providers.dart';
import '../../../app/design_system/daram_widgets.dart';
import '../../../app/theme/daram_colors.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/formatting/bidi_text.dart';
import '../../../core/formatting/persian_formatting.dart';
import '../../ai/data/open_code_models.dart';
import '../../ai/domain/ai_models.dart';
import '../domain/app_settings.dart';

class AISettingsScreen extends ConsumerStatefulWidget {
  const AISettingsScreen({super.key});

  @override
  ConsumerState<AISettingsScreen> createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends ConsumerState<AISettingsScreen> {
  late AIProviderKind _provider;
  late AIToolMode _toolMode;
  late int _timeout;
  late final TextEditingController _baseUrl;
  late final TextEditingController _model;
  final _apiKey = TextEditingController();
  final Map<AIProviderKind, ({String baseUrl, String model})> _drafts = {};

  String? _storedKey;
  bool _obscureKey = true;
  bool _testing = false;
  bool _saving = false;
  bool _loadingModels = false;
  AIConnectionResult? _result;

  AppSettings get _settings =>
      ref.read(settingsControllerProvider).value ??
      const AppSettings.defaults();

  AIConfig get _current => _settings.aiConfig;

  bool get _hasStoredKey => (_storedKey ?? '').trim().isNotEmpty;

  String get _selectedModel {
    final value = _model.text.trim();
    return value.isEmpty ? _provider.defaultModel : value;
  }

  String get _keyHint => switch (_provider) {
    AIProviderKind.openCode || AIProviderKind.openCodeGo => 'oc_sk_...',
    AIProviderKind.anthropic => 'sk-ant-...',
    AIProviderKind.gemini => 'AIza...',
    AIProviderKind.openAICompatible => 'sk-...',
  };

  @override
  void initState() {
    super.initState();
    final config = _current;
    _provider = config.provider;
    _toolMode = config.toolMode;
    _timeout = config.timeoutSeconds;
    _baseUrl = TextEditingController(
      text: config.provider.usesManagedEndpoint
          ? config.provider.defaultBaseUrl
          : config.baseUrl,
    );
    _model = TextEditingController(text: config.model);
    _storedKey = config.apiKey.trim().isEmpty ? null : config.apiKey;
    unawaited(_loadStoredKey(_provider));
  }

  @override
  void dispose() {
    _baseUrl.dispose();
    _model.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  Future<void> _loadStoredKey(AIProviderKind provider) async {
    String? key;
    try {
      key = await ref
          .read(settingsControllerProvider.notifier)
          .storedApiKey(provider);
    } on Object {
      key = null;
    }
    if (!mounted || provider != _provider) return;
    setState(() => _storedKey = key);
  }

  void _applyProvider(AIProviderKind provider) {
    if (provider == _provider) return;
    _drafts[_provider] = (baseUrl: _baseUrl.text, model: _model.text);
    final draft = _drafts[provider];
    setState(() {
      _provider = provider;
      _baseUrl.text = provider.usesManagedEndpoint
          ? provider.defaultBaseUrl
          : (draft?.baseUrl ?? provider.defaultBaseUrl);
      _model.text = draft?.model ?? provider.defaultModel;
      _apiKey.clear();
      _storedKey = null;
      _result = null;
    });
    unawaited(_loadStoredKey(provider));
  }

  AIConfig _buildConfig() {
    final enteredKey = _apiKey.text.trim();
    final storedKey = (_storedKey ?? '').trim();
    return AIConfig(
      provider: _provider,
      baseUrl: _provider.usesManagedEndpoint
          ? _provider.defaultBaseUrl
          : _baseUrl.text.trim(),
      model: _selectedModel,
      apiKey: enteredKey.isNotEmpty ? enteredKey : storedKey,
      timeoutSeconds: _timeout,
      toolMode: _toolMode,
      maxTokens: _current.maxTokens,
      temperature: _current.temperature,
    );
  }

  Future<void> _test() async {
    final config = _buildConfig();
    final error = config.validate();
    if (error != null) {
      setState(() => _result = AIConnectionResult.failure(error));
      return;
    }
    setState(() {
      _testing = true;
      _result = null;
    });
    final result = await ref
        .read(aiProviderRegistryProvider)
        .forKind(config.provider)
        .testConnection(config);
    if (!mounted) return;
    setState(() {
      _testing = false;
      _result = result;
    });
  }

  Future<void> _pickModel() async {
    final config = _buildConfig();
    setState(() {
      _loadingModels = true;
      _result = null;
    });
    try {
      final models = await ref.read(openCodeModelsProvider).list(config);
      if (!mounted) return;
      // Stop the field's loading spinner before the picker sheet animates in;
      // otherwise the indeterminate spinner keeps pumpAndSettle (and the UI)
      // busy underneath the sheet.
      setState(() => _loadingModels = false);
      if (models.isEmpty) {
        setState(
          () => _result = const AIConnectionResult.failure(
            'مدلی برای این کلید یا این حساب پیدا نشد.',
          ),
        );
        return;
      }
      final picked = await showModalBottomSheet<AIModelOption>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        backgroundColor: context.daram.surface,
        builder: (_) => _ModelPickerSheet(
          provider: _provider,
          models: models,
          selectedId: _selectedModel,
        ),
      );
      if (picked == null || !mounted) return;
      setState(() {
        _model.text = picked.id;
        _result = null;
      });
    } on AppException catch (error) {
      if (mounted) {
        setState(() => _result = AIConnectionResult.failure(error.message));
      }
    } on Object {
      if (mounted) {
        setState(
          () => _result = const AIConnectionResult.failure(
            'دریافت فهرست مدل‌ها ممکن نشد. اتصال اینترنت را بررسی کن.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingModels = false);
    }
  }

  Future<void> _save() async {
    final config = _buildConfig();
    final error = config.validate();
    if (error != null) {
      setState(() => _result = AIConnectionResult.failure(error));
      return;
    }
    final enteredKey = _apiKey.text.trim();
    setState(() => _saving = true);
    await ref
        .read(settingsControllerProvider.notifier)
        .saveAIConfig(config, replaceApiKey: enteredKey.isNotEmpty);
    if (!mounted) return;
    if (enteredKey.isNotEmpty) _storedKey = enteredKey;
    _apiKey.clear();
    setState(() => _saving = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('تنظیمات دستیار ذخیره شد.')));
    await _loadStoredKey(_provider);
  }

  Future<void> _clearKey() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف کلید API'),
        content: Text(
          'کلید ذخیره‌شده ${_provider.label} از حافظه امن دستگاه حذف شود؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.daram.expense,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(settingsControllerProvider.notifier).clearApiKey(_provider);
    if (!mounted) return;
    setState(() {
      _storedKey = null;
      _result = null;
    });
  }

  Widget _buildApiKeyField(BuildContext context) {
    final colors = context.daram;
    return TextField(
      controller: _apiKey,
      obscureText: _obscureKey,
      textDirection: TextDirection.ltr,
      decoration: InputDecoration(
        hintText: _hasStoredKey ? 'کلید ذخیره شده است' : _keyHint,
        helperText: _hasStoredKey
            ? 'برای تغییر، کلید جدید را وارد کن.'
            : _provider.usesManagedEndpoint
            ? 'فقط کلید همین سرویس‌دهنده لازم است.'
            : null,
        prefixIcon: const Icon(LucideIcons.lock, size: 17),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => setState(() => _obscureKey = !_obscureKey),
              icon: Icon(
                _obscureKey ? LucideIcons.eye : LucideIcons.eyeOff,
                size: 17,
              ),
            ),
            if (_hasStoredKey)
              IconButton(
                onPressed: _clearKey,
                tooltip: 'حذف کلید',
                icon: Icon(LucideIcons.trash2, size: 17, color: colors.expense),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final managed = _provider.usesManagedEndpoint;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        centerTitle: false,
        title: const Text('دستیار هوشمند'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(LucideIcons.arrowRight, size: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          DaramCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.accentSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    LucideIcons.keyRound,
                    size: 18,
                    color: colors.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'کلید متعلق به خودت (BYOK)',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        'کلید در حافظه امن دستگاه می‌ماند. برای OpenCode فقط کلید و مدل لازم است.',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: colors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (kIsWeb) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colors.warning.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.circleAlert,
                    size: 17,
                    color: colors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'در نسخه وب، سرویس‌دهنده باید درخواست‌های مستقیم مرورگر (CORS) را مجاز کند. '
                      'کلید API فقط روی HTTPS یا localhost در حافظه امن مرورگر ذخیره می‌شود؛ '
                      'اگر ذخیره کلید ممکن نشد، از نسخه اندروید یا دسکتاپ استفاده کن. '
                      'پاسخ‌ها در مرورگر پس از تکمیل دریافت می‌شوند (بدون نمایش تدریجی).',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colors.textSecondary, height: 1.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _FieldLabel('سرویس‌دهنده'),
          DropdownButtonFormField<AIProviderKind>(
            key: ValueKey(_provider),
            initialValue: _provider,
            isExpanded: true,
            decoration: const InputDecoration(),
            items: [
              for (final provider in AIProviderKind.values)
                DropdownMenuItem(value: provider, child: Text(provider.label)),
            ],
            onChanged: (value) {
              if (value != null) _applyProvider(value);
            },
          ),
          if (managed) ...[
            const SizedBox(height: 10),
            _OpenCodeNote(provider: _provider),
          ],
          const SizedBox(height: 14),
          _FieldLabel('کلید دسترسی (API)'),
          _buildApiKeyField(context),
          if (managed) ...[
            const SizedBox(height: 14),
            _FieldLabel('مدل'),
            _ManagedModelCard(
              provider: _provider,
              model: _selectedModel,
              loading: _loadingModels,
              onTap: _loadingModels ? null : _pickModel,
            ),
            const SizedBox(height: 6),
            Text(
              'آدرس سرویس ثابت است و خودکار تنظیم می‌شود. اگر مدل را تغییر ندادی، مدل پیش‌فرض استفاده می‌شود.',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: colors.textMuted, height: 1.7),
            ),
          ] else ...[
            const SizedBox(height: 14),
            _FieldLabel('آدرس سرویس ${isolateLtr('(Base URL)')}'),
            TextField(
              controller: _baseUrl,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                hintText: _provider.defaultBaseUrl,
                prefixIcon: const Icon(LucideIcons.globe, size: 17),
              ),
            ),
            const SizedBox(height: 14),
            _FieldLabel('نام مدل'),
            TextField(
              controller: _model,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                hintText: _provider.defaultModel,
                prefixIcon: const Icon(LucideIcons.cpu, size: 17),
              ),
            ),
          ],
          const SizedBox(height: 18),
          _FieldLabel('نحوه فراخوانی ابزار'),
          SegmentedButton<AIToolMode>(
            segments: const [
              ButtonSegment(
                value: AIToolMode.native,
                label: Text('Function calling'),
                icon: Icon(LucideIcons.wrench, size: 14),
              ),
              ButtonSegment(
                value: AIToolMode.json,
                label: Text('JSON'),
                icon: Icon(LucideIcons.braces, size: 14),
              ),
            ],
            selected: {_toolMode},
            showSelectedIcon: false,
            onSelectionChanged: (value) =>
                setState(() => _toolMode = value.first),
          ),
          const SizedBox(height: 6),
          Text(
            _toolMode == AIToolMode.native
                ? 'مناسب مدل‌هایی که از ابزارهای بومی پشتیبانی می‌کنند؛ مانند ${isolateLtr('OpenAI / Claude / Gemini / OpenCode')}.'
                : 'برای مدل‌های بدون پشتیبانی ابزار؛ پاسخ‌ها به‌صورت ${isolateLtr('JSON')} معتبر خوانده می‌شوند.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: 14),
          _FieldLabel('زمان انتظار (ثانیه)'),
          DropdownButtonFormField<int>(
            initialValue: _timeout,
            isExpanded: true,
            decoration: const InputDecoration(),
            items: const [
              DropdownMenuItem(value: 30, child: Text('۳۰ ثانیه')),
              DropdownMenuItem(value: 60, child: Text('۶۰ ثانیه')),
              DropdownMenuItem(value: 90, child: Text('۹۰ ثانیه')),
              DropdownMenuItem(value: 120, child: Text('۱۲۰ ثانیه')),
              DropdownMenuItem(value: 180, child: Text('۱۸۰ ثانیه')),
            ],
            onChanged: (value) => setState(() => _timeout = value ?? _timeout),
          ),
          const SizedBox(height: 18),
          if (_result != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (_result!.ok ? colors.income : colors.expense)
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (_result!.ok ? colors.income : colors.expense)
                      .withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _result!.ok
                        ? LucideIcons.circleCheck
                        : LucideIcons.circleAlert,
                    size: 16,
                    color: _result!.ok ? colors.income : colors.expense,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _result!.message,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _result!.ok ? colors.income : colors.expense,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _testing ? null : _test,
                  icon: _testing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(LucideIcons.wifi, size: 16),
                  label: const Text('تست اتصال'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  label: 'ذخیره',
                  loading: _saving,
                  onPressed: _saving ? null : _save,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => context.push('/settings/logs'),
            icon: const Icon(LucideIcons.scrollText, size: 16),
            label: const Text('مشاهده گزارش‌های دستیار'),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.shieldCheck,
                      size: 16,
                      color: colors.income,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'حریم خصوصی',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'فقط اطلاعات لازم برای هر درخواست (متن گفتگو، فهرست حساب‌ها و دسته‌بندی‌ها) به سرویس‌دهنده‌ای که خودت انتخاب کرده‌ای فرستاده می‌شود. کل پایگاه داده هرگز آپلود نمی‌شود. بدون اتصال هم می‌توانی داده‌ها و گزارش‌ها را ببینی.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colors.textSecondary, height: 1.8),
                ),
                const SizedBox(height: 8),
                Text(
                  'برای عیب‌یابی، فقط رویدادهای فنی درخواست‌ها در همین دستگاه ذخیره می‌شود؛ کلید API هرگز در گزارش‌ها نیست.',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: colors.textMuted, height: 1.7),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenCodeNote extends StatelessWidget {
  const _OpenCodeNote({required this.provider});

  final AIProviderKind provider;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final go = provider == AIProviderKind.openCodeGo;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.accent.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            go ? LucideIcons.sparkles : LucideIcons.cloud,
            size: 17,
            color: colors.accent,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  go ? 'OpenCode Go (اشتراک)' : 'OpenCode (پرداخت اعتباری)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  go
                      ? 'برای استفاده از Go به اشتراک Go / Go Plus / Go Teams و کلید Console نیاز داری. آدرس سرویس ثابت است؛ فقط کلید را وارد کن و در صورت نیاز مدل را از فهرست زنده انتخاب کن.'
                      : 'هزینه به‌ازای مصرف از موجودی Console کم می‌شود. کلید را از Console ← Account ← Personal API keys بساز. آدرس ثابت است؛ فقط کلید و مدل لازم است.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colors.textSecondary, height: 1.7),
                ),
                const SizedBox(height: 4),
                Text(
                  'آدرس ثابت: ${isolateLtr(provider.defaultBaseUrl)}',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: colors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagedModelCard extends StatelessWidget {
  const _ManagedModelCard({
    required this.provider,
    required this.model,
    required this.loading,
    required this.onTap,
  });

  final AIProviderKind provider;
  final String model;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colors.accentSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(LucideIcons.cpu, size: 17, color: colors.accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.ltr,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      'انتخاب از کاتالوگ زنده',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: colors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: 'دریافت مدل‌ها از ${provider.label}',
                child: TextButton.icon(
                  onPressed: loading ? null : onTap,
                  icon: loading
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(LucideIcons.list, size: 15),
                  label: const Text('انتخاب مدل'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModelPickerSheet extends StatefulWidget {
  const _ModelPickerSheet({
    required this.provider,
    required this.models,
    required this.selectedId,
  });

  final AIProviderKind provider;
  final List<AIModelOption> models;
  final String selectedId;

  @override
  State<_ModelPickerSheet> createState() => _ModelPickerSheetState();
}

class _ModelPickerSheetState extends State<_ModelPickerSheet> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _normalize(String value) => value.toLowerCase().trim();

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final query = _normalize(_search.text);
    final filtered = widget.models
        .where(
          (model) =>
              _normalize(model.name).contains(query) ||
              _normalize(model.id).contains(query),
        )
        .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SizedBox(
        height: (screenHeight - keyboard) * 0.74,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 10, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مدل‌های ${widget.provider.label}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '${PersianDigits.toPersian('${widget.models.length}')} مدل از کاتالوگ زنده',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  SoftIconButton(
                    icon: LucideIcons.x,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'جست‌وجوی مدل…',
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _search.clear();
                            setState(() {});
                          },
                          icon: const Icon(LucideIcons.x, size: 16),
                        ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'مدلی با این نام پیدا نشد.',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: colors.textMuted),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final model = filtered[index];
                        final selected = model.id == widget.selectedId;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Material(
                            color: selected
                                ? colors.accentSoft
                                : colors.surfaceMuted,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => Navigator.of(context).pop(model),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      LucideIcons.cpu,
                                      size: 18,
                                      color: selected
                                          ? colors.accent
                                          : colors.textMuted,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            model.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            [
                                              model.id,
                                              if (model.contextWindow != null)
                                                '${PersianDigits.toPersian('${model.contextWindow! ~/ 1000}')}K context',
                                              if (model.supportsTools == false)
                                                'بدون ابزار بومی',
                                            ].join(' · '),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color:
                                                      model.supportsTools ==
                                                          false
                                                      ? colors.warning
                                                      : colors.textMuted,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (selected)
                                      Icon(
                                        LucideIcons.check,
                                        size: 17,
                                        color: colors.accent,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, right: 2),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: context.daram.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
