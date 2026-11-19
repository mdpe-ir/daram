import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/app_providers.dart';
import '../../../app/design_system/daram_widgets.dart';
import '../../../app/theme/daram_colors.dart';
import '../../../core/formatting/bidi_text.dart';
import '../../../core/money/currency.dart';
import '../../../data/database/app_database.dart';
import '../../chat/domain/drafts.dart';
import '../../chat/presentation/draft_editor.dart';
import '../data/sms_inbox.dart';
import '../data/sms_review_repository.dart';
import 'sms_controller.dart';

class SmsReviewScreen extends ConsumerStatefulWidget {
  const SmsReviewScreen({super.key});

  @override
  ConsumerState<SmsReviewScreen> createState() => _SmsReviewScreenState();
}

class _SmsReviewScreenState extends ConsumerState<SmsReviewScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() work) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await work();
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('این تغییر انجام نشد. دوباره تلاش کن.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit(SmsSuggestionRow row) async {
    final settings = ref.read(settingsControllerProvider).value;
    final payload = await showDraftEditor(
      context,
      draft: SmsReviewRepository.draftOf(row),
      defaultCurrency: settings?.currencyUnit ?? CurrencyUnit.toman,
    );
    if (payload == null || !mounted) return;
    await _run(
      () => ref
          .read(smsReviewRepositoryProvider)
          .confirm(row.id, edited: TransactionDraft.fromPayload(payload)),
    );
  }

  Future<void> _dismiss(SmsSuggestionRow row) async {
    final ignorePattern = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('رد کردن پیشنهاد'),
        content: const Text(
          'می‌توانی فقط این مورد را رد کنی یا قالب مشابه را هم برای این سرشماره کنار بگذاری.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('بازگشت'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('فقط همین مورد'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('این قالب تراکنش نیست'),
          ),
        ],
      ),
    );
    if (ignorePattern == null || !mounted) return;
    await _run(
      () => ref
          .read(smsReviewRepositoryProvider)
          .dismiss(row.id, ignorePattern: ignorePattern),
    );
  }

  Future<void> _showSource(SmsSuggestionRow row) async {
    final inbox = ref.read(smsInboxProvider);
    final source = Future.wait([
      inbox.message(row.id),
      if (row.contextMessageId case final receipt?) inbox.message(receipt),
    ]);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('متن پیامک'),
        content: FutureBuilder<List<String?>>(
          future: source,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                heightFactor: 2,
                child: CircularProgressIndicator(),
              );
            }
            final messages = snapshot.data?.whereType<String>().toList() ?? [];
            return SingleChildScrollView(
              child: SelectableText(
                messages.isEmpty
                    ? 'پیامک در صندوق گوشی پیدا نشد یا دسترسی پیامک غیرفعال است.'
                    : messages.join('\n\n'),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('بستن'),
          ),
        ],
      ),
    );
  }

  Future<void> _enable() async {
    final enabled = await ref.read(smsControllerProvider.notifier).enable();
    if (enabled || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('دسترسی پیامک داده نشد.'),
        action: SnackBarAction(
          label: 'تنظیمات اندروید',
          onPressed: () => ref.read(smsInboxProvider).openSettings(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!SmsInbox.supported) {
      return Scaffold(
        appBar: AppBar(title: const Text('بازبینی پیامک‌ها')),
        body: const Center(
          child: Text('خواندن پیامک در نسخهٔ اندروید در دسترس است.'),
        ),
      );
    }
    final state = ref.watch(smsControllerProvider);
    final controller = ref.read(smsControllerProvider.notifier);
    final drafts = ref.watch(smsDraftsProvider);
    final accounts = ref.watch(accountsStreamProvider).value ?? const [];
    final categories = ref.watch(categoriesStreamProvider).value ?? const [];
    final rows = drafts.value ?? const <SmsSuggestionRow>[];
    final aiConfigured =
        ref.watch(settingsControllerProvider).value?.isAIConfigured == true;
    final activeAccountIds = {for (final item in accounts) item.account.id};
    final categoryIds = {for (final item in categories) item.id};
    final ready = {
      for (final row in rows)
        if (row.status == 'pending' &&
            activeAccountIds.contains(
              SmsReviewRepository.draftOf(row).accountId,
            ) &&
            (SmsReviewRepository.draftOf(row).categoryId == null ||
                categoryIds.contains(
                  SmsReviewRepository.draftOf(row).categoryId,
                )))
          row.id,
    };
    return Scaffold(
      appBar: AppBar(
        title: const Text('بازبینی پیامک‌ها'),
        actions: [
          IconButton(
            tooltip: 'بررسی صندوق پیامک',
            onPressed: state.enabled && !state.scanning
                ? controller.refresh
                : null,
            icon: const Icon(LucideIcons.refreshCw),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: rows.length + 1,
          itemBuilder: (context, index) {
            if (index > 0) {
              final row = rows[index - 1];
              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _ReviewCard(
                  row: row,
                  onShowSource: state.enabled ? () => _showSource(row) : null,
                  ready: ready.contains(row.id),
                  onConfirm: _busy
                      ? null
                      : () => _run(
                          () => ref
                              .read(smsReviewRepositoryProvider)
                              .confirm(row.id),
                        ),
                  onEdit: _busy ? null : () => _edit(row),
                  onDismiss: _busy ? null : () => _dismiss(row),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DaramCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Material(
                    type: MaterialType.transparency,
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('بررسی خودکار پیامک‌ها'),
                          subtitle: const Text(
                            'سرشماره‌های هر حساب را از جزئیات همان حساب انتخاب کن.',
                          ),
                          value: state.enabled,
                          onChanged: _busy
                              ? null
                              : (value) =>
                                    _run(value ? _enable : controller.disable),
                        ),
                        if (state.enabled)
                          SwitchListTile(
                            title: const Text('تشخیص قالب با هوش مصنوعی'),
                            subtitle: const Text(
                              'قالب اعلان‌های بانکی و رسیدهای مرتبط، با اعداد و پیوندهای پوشانده‌شده، به سرویس مدل تو فرستاده می‌شود.',
                            ),
                            value: state.aiEnabled,
                            onChanged: _busy
                                ? null
                                : (value) => _run(
                                    () => controller.setAiEnabled(value),
                                  ),
                          ),
                        if (state.enabled && state.aiEnabled && !aiConfigured)
                          TextButton(
                            onPressed: () => context.push('/settings/ai'),
                            child: const Text('تنظیم سرویس هوش مصنوعی'),
                          ),
                      ],
                    ),
                  ),
                ),
                if (state.scanning) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(
                    semanticsLabel: 'در حال بررسی پیامک‌ها',
                  ),
                ],
                if (state.error case final error?)
                  ListTile(
                    leading: const Icon(LucideIcons.circleAlert),
                    title: Text(error),
                    onTap: () => ref.read(smsInboxProvider).openSettings(),
                  ),
                if (state.candidates.isNotEmpty)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(LucideIcons.messageSquare),
                    title: const Text('سرشماره‌های بانکی اضافه‌نشده'),
                    trailing: const Icon(LucideIcons.chevronLeft),
                    onTap: () => context.push('/sms/senders'),
                  ),
                const SizedBox(height: 12),
                if (rows.isNotEmpty)
                  Text(
                    'در انتظار بازبینی',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                if (ready.length > 1)
                  FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _run(() async {
                            final repository = ref.read(
                              smsReviewRepositoryProvider,
                            );
                            for (final id in ready) {
                              await repository.confirm(id);
                            }
                          }),
                    icon: const Icon(LucideIcons.checkCheck),
                    label: const Text('تأیید همهٔ موارد آماده'),
                  ),
                if (drafts.hasError)
                  const Text('خواندن پیشنهادها ممکن نشد.')
                else if (drafts.isLoading && rows.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (state.enabled && rows.isEmpty && !state.scanning)
                  const Text('پیشنهاد تازه‌ای برای بازبینی نداری.'),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.row,
    required this.ready,
    required this.onConfirm,
    required this.onEdit,
    required this.onDismiss,
    required this.onShowSource,
  });

  final SmsSuggestionRow row;
  final bool ready;
  final VoidCallback? onConfirm;
  final VoidCallback? onEdit;
  final VoidCallback? onDismiss;
  final VoidCallback? onShowSource;

  @override
  Widget build(BuildContext context) {
    final draft = SmsReviewRepository.draftOf(row);
    final format = DaramFormatScope.of(context);
    final heading = draft.description?.trim();
    return DaramCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading == null || heading.isEmpty ? 'تراکنش پیامکی' : heading,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          if (!draft.amountRial.isZero)
            AmountText(
              draft.amountRial,
              color: draft.type.name == 'income'
                  ? context.daram.income
                  : context.daram.expense,
            )
          else
            const Text('مبلغ نیاز به بررسی دارد'),
          Text(
            [
              if (!draft.amountRial.isZero) draft.type.labelFa,
              if (draft.accountName.isNotEmpty) draft.accountName,
              ?draft.categoryName,
              format.dates.relative(draft.date),
              isolateLtr(row.sender),
            ].join(' · '),
          ),
          if (row.contextMessageId != null)
            const Text('با پیامک مرتبط تطبیق داده شد.'),
          if (!ready) const Text('برای ثبت، جزئیات تراکنش را بررسی کن.'),
          if (onShowSource != null)
            TextButton.icon(
              onPressed: onShowSource,
              icon: const Icon(LucideIcons.messageSquare, size: 16),
              label: const Text('نمایش پیامک'),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (ready)
                FilledButton(onPressed: onConfirm, child: const Text('تأیید')),
              OutlinedButton(
                onPressed: onEdit,
                child: const Text('ویرایش و تأیید'),
              ),
              TextButton(onPressed: onDismiss, child: const Text('رد کردن')),
            ],
          ),
        ],
      ),
    );
  }
}
