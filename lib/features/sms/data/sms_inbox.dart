import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/sms_message.dart';

class SmsInbox {
  static const _channel = MethodChannel('ir.daram.daram/sms');
  static const _pageSize = 400;

  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<bool> hasPermission() async =>
      supported &&
      (await _channel.invokeMethod<bool>('hasPermission') ?? false);

  Future<bool> requestPermission() async =>
      supported &&
      (await _channel.invokeMethod<bool>('requestPermission') ?? false);

  Future<void> openSettings() => _channel.invokeMethod<void>('openSettings');

  Future<void> observe(VoidCallback? onChange) async {
    if (!supported) return;
    _channel.setMethodCallHandler(
      onChange == null
          ? null
          : (call) async {
              if (call.method == 'inboxChanged') onChange();
            },
    );
    await _channel.invokeMethod<void>('observe', onChange != null);
  }

  Future<Map<String, List<String>>> senders() async {
    final addresses = await _channel.invokeListMethod<String>('senders') ?? [];
    final grouped = <String, List<String>>{};
    for (final address in addresses) {
      final sender = InboxSms.normalizeSender(address);
      if (sender.isNotEmpty) grouped.putIfAbsent(sender, () => []).add(address);
    }
    return grouped;
  }

  Future<List<String>> examples(List<String> addresses) async =>
      await _channel.invokeListMethod<String>('examples', {
        'addresses': addresses,
      }) ??
      [];

  Future<String?> message(String sourceId) {
    final parts = sourceId.split('-');
    if (parts.length != 2) return Future.value();
    return _channel.invokeMethod<String>('message', {
      'id': int.parse(parts[0]),
      'date': int.parse(parts[1]),
    });
  }

  Stream<InboxSms> readSince(DateTime since) async* {
    int? cursor;
    while (true) {
      final page =
          await _channel.invokeListMethod<Map<Object?, Object?>>('messages', {
            'since': since.millisecondsSinceEpoch,
            'beforeId': cursor,
          }) ??
          [];
      for (final row in page) {
        final id = row['id'] as int;
        final milliseconds = row['date'] as int;
        final sender = InboxSms.normalizeSender(row['sender'] as String);
        final body = row['body'] as String;
        if (sender.isEmpty || body.trim().isEmpty) continue;
        yield InboxSms(
          id: '$id-$milliseconds',
          sender: sender,
          body: body,
          date: DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true),
        );
      }
      if (page.length < _pageSize) return;
      cursor = page.last['id'] as int;
    }
  }
}
