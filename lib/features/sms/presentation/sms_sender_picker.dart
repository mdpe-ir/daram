import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/design_system/daram_widgets.dart';
import '../../../core/formatting/bidi_text.dart';
import '../../../core/formatting/persian_formatting.dart';
import '../../accounts/domain/account.dart';
import '../domain/sms_message.dart';
import 'sms_controller.dart';

Future<bool?> showSmsSenderPicker(
  BuildContext context,
  Account account, {
  String? suggestedSender,
}) => Navigator.of(context, rootNavigator: true).push<bool>(
  MaterialPageRoute(
    builder: (context) =>
        _SenderPicker(account: account, suggestedSender: suggestedSender),
  ),
);

class _SenderPicker extends ConsumerStatefulWidget {
  const _SenderPicker({required this.account, this.suggestedSender});

  final Account account;
  final String? suggestedSender;

  @override
  ConsumerState<_SenderPicker> createState() => _SenderPickerState();
}

class _SenderPickerState extends ConsumerState<_SenderPicker> {
  final _selected = <String>{};
  late Future<Map<String, List<String>>> _senders;
  String _query = '';
  bool _history = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _senders = _load();
  }

  Future<Map<String, List<String>>> _load() async {
    final repository = ref.read(smsReviewRepositoryProvider);
    final inbox = ref.read(smsInboxProvider);
    final controller = ref.read(smsControllerProvider.notifier);
    final canRead =
        ref.read(smsControllerProvider).enabled && await inbox.hasPermission();
    if (!canRead && (!mounted || !await controller.enable())) {
      throw const _PermissionDenied();
    }
    final linked = (await repository.links())
        .where((link) => link.accountId == widget.account.id)
        .map((link) => link.sender)
        .toSet();
    final addresses = await inbox.senders();
    final suggested = widget.suggestedSender;
    _selected.addAll(linked);
    if (suggested != null) _selected.add(suggested);
    return {for (final sender in _selected) sender: const [], ...addresses};
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(smsReviewRepositoryProvider)
          .setSenders(
            widget.account.id,
            Set.of(_selected),
            includeHistory: _history,
          );
      if (!mounted) return;
      unawaited(ref.read(smsControllerProvider.notifier).refresh());
      Navigator.of(context).pop(true);
    } on Object {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ذخیره سرشماره‌ها انجام نشد.')),
      );
    }
  }

  Future<void> _preview(String sender, List<String> addresses) async {
    final samples = ref.read(smsInboxProvider).examples(addresses);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('نمونه پیامک ${isolateLtr(sender)}'),
        content: FutureBuilder<List<String>>(
          future: samples,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                heightFactor: 2,
                child: CircularProgressIndicator(),
              );
            }
            final messages = [
              for (final body in snapshot.data ?? const <String>[])
                SmsShape(
                      InboxSms(
                        id: '',
                        sender: sender,
                        body: body,
                        date: DateTime.now(),
                      ),
                    ).isAuthentication
                    ? 'پیامک رمز یا تأیید ورود'
                    : body,
            ];
            return SingleChildScrollView(
              child: Text(
                messages.isEmpty
                    ? 'نمونه‌ای در صندوق پیامک پیدا نشد.'
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

  @override
  Widget build(BuildContext context) {
    final candidates = ref.watch(smsControllerProvider).candidates;
    final recommended = {
      for (final candidate in candidates)
        if (candidate.accountIds.contains(widget.account.id)) candidate.sender,
    };
    return Scaffold(
      appBar: AppBar(
        title: const Text('انتخاب سرشماره‌ها'),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, List<String>>>(
          future: _senders,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              final denied = snapshot.error is _PermissionDenied;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        denied
                            ? 'برای انتخاب از صندوق پیامک، دسترسی پیامک را در تنظیمات اندروید فعال کن.'
                            : 'خواندن سرشماره‌های پیامک ممکن نشد.',
                      ),
                      if (denied)
                        TextButton(
                          onPressed: () =>
                              ref.read(smsInboxProvider).openSettings(),
                          child: const Text('تنظیمات اندروید'),
                        ),
                      FilledButton(
                        onPressed: () => setState(() => _senders = _load()),
                        child: const Text('تلاش دوباره'),
                      ),
                    ],
                  ),
                ),
              );
            }
            final query = PersianDigits.toLatin(_query).trim().toUpperCase();
            final addresses = snapshot.data!;
            final shown = [
              for (final sender in addresses.keys.where(recommended.contains))
                if (sender.contains(query)) sender,
              for (final sender in addresses.keys.where(
                (sender) => !recommended.contains(sender),
              ))
                if (sender.contains(query)) sender,
            ];
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.account.accountName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'جست‌وجوی سرشماره',
                          prefixIcon: Icon(LucideIcons.search),
                        ),
                        onChanged: (value) => setState(() => _query = value),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: shown.isEmpty
                      ? const Center(child: Text('سرشماره‌ای پیدا نشد.'))
                      : ListView.builder(
                          itemCount: shown.length,
                          itemBuilder: (context, index) {
                            final sender = shown[index];
                            return Row(
                              children: [
                                Expanded(
                                  child: CheckboxListTile(
                                    title: Text(isolateLtr(sender)),
                                    subtitle: recommended.contains(sender)
                                        ? const Text(
                                            'پیشنهاد دارام برای این حساب',
                                          )
                                        : null,
                                    value: _selected.contains(sender),
                                    onChanged: _saving
                                        ? null
                                        : (value) => setState(() {
                                            if (value == true) {
                                              _selected.add(sender);
                                            } else {
                                              _selected.remove(sender);
                                            }
                                          }),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'نمونه پیامک ${isolateLtr(sender)}',
                                  onPressed: addresses[sender]!.isEmpty
                                      ? null
                                      : () => _preview(
                                          sender,
                                          addresses[sender]!,
                                        ),
                                  icon: const Icon(LucideIcons.eye),
                                ),
                              ],
                            );
                          },
                        ),
                ),
                SwitchListTile(
                  title: const Text('بررسی پیامک‌های ۳۰ روز گذشته'),
                  subtitle: const Text(
                    'ممکن است بعضی از آن‌ها را قبلاً ثبت کرده باشی.',
                  ),
                  value: _history,
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _history = value),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: 'ذخیره سرشماره‌ها',
                      loading: _saving,
                      onPressed: _saving ? null : _save,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PermissionDenied implements Exception {
  const _PermissionDenied();
}
