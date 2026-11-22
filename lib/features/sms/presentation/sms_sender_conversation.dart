import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/app_providers.dart';
import '../../../app/design_system/daram_widgets.dart';
import '../../../core/formatting/bidi_text.dart';
import '../../../core/formatting/persian_formatting.dart';
import '../../../core/time/calendar_date.dart';
import '../../../app/theme/daram_colors.dart';
import '../../accounts/domain/account.dart';
import '../data/sms_scan_service.dart';
import 'sms_controller.dart';
import 'sms_sender_picker.dart';

class SmsSenderConversation extends ConsumerStatefulWidget {
  const SmsSenderConversation({super.key});

  @override
  ConsumerState<SmsSenderConversation> createState() =>
      _SmsSenderConversationState();
}

class _SmsSenderConversationState extends ConsumerState<SmsSenderConversation> {
  final _handled = <String>{};
  final _dismissing = <String>{};
  final _linked = <String>[];
  final _reply = TextEditingController();
  String? _feedback;

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _sendReply(
    List<SenderCandidate> candidates,
    List<Account> accounts,
  ) async {
    final raw = _reply.text.trim();
    if (raw.isEmpty) return;
    final text = PersianDigits.toLatin(raw)
        .toUpperCase()
        .replaceAll('ي', 'ی')
        .replaceAll('ك', 'ک')
        .replaceAll('‌', ' ');
    final named = candidates
        .where(
          (candidate) => RegExp(
            '(?:^|[^0-9A-Z])${RegExp.escape(candidate.sender)}'
            r'(?=$|[^0-9A-Z])',
          ).hasMatch(text),
        )
        .toList();
    final candidate = named.length == 1
        ? named.single
        : named.isEmpty && candidates.length == 1
        ? candidates.single
        : null;
    if (candidate == null) {
      setState(
        () => _feedback = 'سرشماره را در جوابت بنویس یا از فهرست انتخابش کن.',
      );
      return;
    }
    final fromReply = accounts.where((account) {
      final name = account.accountName.toUpperCase().replaceAll('‌', ' ');
      final bank = account.bankName.replaceFirst('بانک ', '').toUpperCase();
      return (name.isNotEmpty && text.contains(name)) ||
          (bank.length > 2 && text.contains(bank));
    }).toList();
    _reply.clear();
    setState(() => _feedback = null);
    if (fromReply.length == 1) {
      await _link(candidate, fromReply.single);
    } else {
      await _choose(candidate, fromReply.isEmpty ? accounts : fromReply);
    }
  }

  Future<void> _choose(
    SenderCandidate candidate,
    List<Account> accounts,
  ) async {
    final ordered = [
      ...accounts.where((account) => candidate.accountIds.contains(account.id)),
      ...accounts.where(
        (account) => !candidate.accountIds.contains(account.id),
      ),
    ];
    final account = await showDialog<Account>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(
          'پیامک‌های ${isolateLtr(candidate.sender)} برای کدام حساب‌اند؟',
        ),
        children: [
          if (accounts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('اول در بخش حساب‌ها یک حساب بانکی اضافه کن.'),
            ),
          for (final account in ordered)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(account),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(account.accountName),
                subtitle: Text(
                  candidate.accountIds.contains(account.id)
                      ? '${account.bankName} · پیشنهاد دارام'
                      : account.bankName,
                ),
              ),
            ),
        ],
      ),
    );
    if (account == null || !mounted) return;
    await _link(candidate, account);
  }

  Future<void> _link(SenderCandidate candidate, Account account) async {
    final saved = await showSmsSenderPicker(
      context,
      account,
      suggestedSender: candidate.sender,
    );
    if (saved != true || !mounted) return;
    final links = await ref.read(smsReviewRepositoryProvider).links();
    if (!mounted ||
        !links.any(
          (link) =>
              link.sender == candidate.sender && link.accountId == account.id,
        )) {
      return;
    }
    setState(() {
      _handled.add(candidate.sender);
      _linked.add(
        '${isolateLtr(candidate.sender)} را به «${account.accountName}» وصل کردم.',
      );
    });
  }

  Future<void> _dismiss(String sender) async {
    setState(() => _dismissing.add(sender));
    try {
      await ref.read(smsControllerProvider.notifier).dismissSender(sender);
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('حذف پیشنهاد انجام نشد.')));
    } finally {
      if (mounted) setState(() => _dismissing.remove(sender));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smsControllerProvider);
    final candidates = state.candidates
        .where((item) => !_handled.contains(item.sender))
        .toList();
    final accounts =
        ref
            .watch(accountsStreamProvider)
            .value
            ?.map((item) => item.account)
            .toList() ??
        const <Account>[];
    final format = DaramFormatScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('گفتگو دربارهٔ سرشماره‌ها')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 1 + _linked.length + candidates.length,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return DaramCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            candidates.isNotEmpty
                                ? 'این سرشماره‌ها احتمالاً بانکی‌اند. برای هرکدام حسابش را انتخاب کن.'
                                : state.scanning
                                ? 'دارم دنبال سرشماره‌های بانکی می‌گردم…'
                                : state.error ?? 'فعلاً سرشمارهٔ بانکی تازه‌ای پیدا نکردم.',
                          ),
                          if (state.error != null && candidates.isNotEmpty)
                            Text(state.error!),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: state.scanning || !state.enabled
                                ? null
                                : () {
                                    setState(() => _feedback = null);
                                    ref
                                        .read(smsControllerProvider.notifier)
                                        .refresh();
                                  },
                            icon: const Icon(LucideIcons.refreshCw, size: 16),
                            label: const Text('بررسی دوباره'),
                          ),
                          if (state.scanning)
                            const LinearProgressIndicator(
                              semanticsLabel: 'در حال بررسی پیامک‌ها',
                            ),
                        ],
                      ),
                    );
                  }
                  if (index <= _linked.length) {
                    return ListTile(
                      leading: const Icon(LucideIcons.check),
                      title: Text(_linked[index - 1]),
                    );
                  }
                  final candidate = candidates[index - _linked.length - 1];
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: DaramCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  isolateLtr(candidate.sender),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                              ),
                              IconButton(
                                tooltip: 'حذف پیشنهاد',
                                onPressed:
                                    _dismissing.contains(candidate.sender)
                                    ? null
                                    : () => _dismiss(candidate.sender),
                                icon: const Icon(LucideIcons.trash2, size: 18),
                              ),
                            ],
                          ),
                          Text(
                            '${format.persianDigits ? PersianDigits.toPersian('${candidate.count}') : candidate.count} پیامک احتمالی بانک',
                          ),
                          for (final sample in candidate.examples)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: context.daram.surfaceMuted,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sample.body.trim(),
                                    maxLines: 6,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    format.dates.date(
                                      CalendarDate.fromDateTime(
                                        sample.date.toLocal(),
                                      ),
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: TextButton.icon(
                              onPressed: _dismissing.contains(candidate.sender)
                                  ? null
                                  : () => _choose(candidate, accounts),
                              icon: const Icon(LucideIcons.link, size: 16),
                              label: const Text('انتخاب حساب'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_feedback case final message?)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(message),
              ),
            if (candidates.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _reply,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendReply(candidates, accounts),
                  decoration: InputDecoration(
                    labelText: 'سرشماره و نام حساب',
                    hintText: 'مثلاً ۱۰۰۱۲۳ برای حساب ملت',
                    suffixIcon: IconButton(
                      tooltip: 'ارسال جواب',
                      icon: const Icon(LucideIcons.send),
                      onPressed: () => _sendReply(candidates, accounts),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
