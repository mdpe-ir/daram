import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/app_providers.dart';
import '../../../app/design_system/daram_widgets.dart';
import '../../../app/theme/daram_colors.dart';
import '../../../core/formatting/bidi_text.dart';
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
  bool _obscureKey = true;
  bool _testing = false;
  bool _saving = false;
  AIConnectionResult? _result;

  AppSettings get _settings =>
      ref.read(settingsControllerProvider).value ??
      const AppSettings.defaults();

  AIConfig get _current => _settings.aiConfig;

  @override
  void initState() {
    super.initState();
    final config = _current;
    _provider = config.provider;
    _toolMode = config.toolMode;
    _timeout = config.timeoutSeconds;
    _baseUrl = TextEditingController(text: config.baseUrl);
    _model = TextEditingController(text: config.model);
  }

  @override
  void dispose() {
    _baseUrl.dispose();
    _model.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  void _applyProvider(AIProviderKind provider) {
    final previous = AIProviderKind.values
        .map((kind) => kind)
        .where((kind) => kind != _provider)
        .toList();
    final defaults = previous.map((kind) => kind.defaultBaseUrl).toSet();
    final modelDefaults = previous.map((kind) => kind.defaultModel).toSet();
    setState(() {
      _provider = provider;
      if (_baseUrl.text.trim().isEmpty ||
          defaults.contains(_baseUrl.text.trim())) {
        _baseUrl.text = provider.defaultBaseUrl;
      }
      if (_model.text.trim().isEmpty ||
          modelDefaults.contains(_model.text.trim())) {
        _model.text = provider.defaultModel;
      }
      _result = null;
    });
  }

  AIConfig _buildConfig() {
    final enteredKey = _apiKey.text.trim();
    return AIConfig(
      provider: _provider,
      baseUrl: _baseUrl.text.trim(),
      model: _model.text.trim(),
      apiKey: enteredKey.isEmpty ? _current.apiKey : enteredKey,
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

  Future<void> _save() async {
    final config = _buildConfig();
    final error = config.validate();
    if (error != null) {
      setState(() => _result = AIConnectionResult.failure(error));
      return;
    }
    setState(() => _saving = true);
    await ref
        .read(settingsControllerProvider.notifier)
        .saveAIConfig(config, replaceApiKey: _apiKey.text.trim().isNotEmpty);
    if (!mounted) return;
    setState(() => _saving = false);
    _apiKey.clear();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('تنظیمات دستیار ذخیره شد.')));
  }

  Future<void> _clearKey() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف کلید API'),
        content: const Text('کلید ذخیره‌شده از حافظه امن دستگاه حذف شود؟'),
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
    if (confirmed == true) {
      await ref.read(settingsControllerProvider.notifier).clearApiKey();
      setState(() => _result = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final hasStoredKey = _settings.hasApiKey;
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
                        'دارام از سرویس اختصاصی تو استفاده می‌کند؛ کلید در حافظه امن دستگاه ذخیره می‌شود.',
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
            initialValue: _provider,
            decoration: const InputDecoration(),
            items: [
              for (final provider in AIProviderKind.values)
                DropdownMenuItem(value: provider, child: Text(provider.label)),
            ],
            onChanged: (value) {
              if (value != null) _applyProvider(value);
            },
          ),
          const SizedBox(height: 14),
          _FieldLabel('آدرس سرویس ${isolateLtr('(Base URL)')}'),
          TextField(
            controller: _baseUrl,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              hintText: 'https://api.openai.com/v1',
              prefixIcon: Icon(LucideIcons.globe, size: 17),
            ),
          ),
          const SizedBox(height: 14),
          _FieldLabel('نام مدل'),
          TextField(
            controller: _model,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              hintText: 'gpt-4o-mini',
              prefixIcon: Icon(LucideIcons.cpu, size: 17),
            ),
          ),
          const SizedBox(height: 14),
          _FieldLabel('کلید دسترسی (API)'),
          TextField(
            controller: _apiKey,
            obscureText: _obscureKey,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              hintText: hasStoredKey ? 'کلید ذخیره شده است' : 'sk-...',
              helperText: hasStoredKey
                  ? 'برای تغییر، کلید جدید را وارد کن.'
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
                  if (hasStoredKey)
                    IconButton(
                      onPressed: _clearKey,
                      tooltip: 'حذف کلید',
                      icon: Icon(
                        LucideIcons.trash2,
                        size: 17,
                        color: colors.expense,
                      ),
                    ),
                ],
              ),
            ),
          ),
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
                ? 'مناسب مدل‌هایی که از ابزارهای بومی پشتیبانی می‌کنند؛ مانند ${isolateLtr('OpenAI / Claude / Gemini')}.'
                : 'برای مدل‌های بدون پشتیبانی ابزار؛ پاسخ‌ها به‌صورت ${isolateLtr('JSON')} معتبر خوانده می‌شوند.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: 14),
          _FieldLabel('زمان انتظار (ثانیه)'),
          DropdownButtonFormField<int>(
            initialValue: _timeout,
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
              ],
            ),
          ),
        ],
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
