import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/app_providers.dart';
import '../../../app/design_system/daram_widgets.dart';
import '../../../core/formatting/bidi_text.dart';
import '../../../core/formatting/persian_formatting.dart';
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
                      child: Text(
                        candidates.isNotEmpty
                            ? 'از این سرشماره‌ها پیامک بانکی پیدا کردم. بگو هرکدام برای کدام حساب است.'
                            : state.scanning
                            ? 'دارم دنبال سرشماره‌های بانکی می‌گردم…'
                            : 'فعلاً سرشمارهٔ بانکی تازه‌ای پیدا نکردم.',
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
                  return ListTile(
                    leading: const Icon(LucideIcons.messageSquare),
                    title: Text(isolateLtr(candidate.sender)),
                    subtitle: Text(
                      '${format.persianDigits ? PersianDigits.toPersian('${candidate.count}') : candidate.count} پیامک احتمالی بانک',
                    ),
                    trailing: const Icon(LucideIcons.chevronLeft),
                    onTap: () => _choose(candidate, accounts),
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
