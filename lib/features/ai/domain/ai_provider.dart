import 'dart:async';

import 'package:flutter/foundation.dart';

import 'ai_models.dart';

/// A provider-agnostic streaming interface for chat completions.
abstract interface class AIProvider {
  /// Streams a completion. Implementations must translate provider errors into
  /// [AIStreamError] with a Persian, user-facing message.
  Stream<AIStreamEvent> streamChat({
    required AIConfig config,
    required List<AIMessage> messages,
    required List<ToolDefinition> tools,
    String? sessionId,
  });

  /// Performs a minimal real request to verify credentials, URL and model.
  Future<AIConnectionResult> testConnection(AIConfig config);
}

/// Maps transport/HTTP failures to concise Persian messages.
String persianAIError(Object error, {int? statusCode}) {
  if (statusCode != null) {
    return switch (statusCode) {
      400 => 'درخواست توسط سرویس‌دهنده رد شد. تنظیمات مدل را بررسی کنید.',
      401 || 403 => 'کلید API نامعتبر است یا دسترسی ندارد.',
      404 => 'آدرس سرویس یا نام مدل پیدا نشد.',
      408 => 'سرویس‌دهنده پاسخ نداد. دوباره تلاش کنید.',
      413 => 'متن گفتگو برای این مدل بسیار طولانی است.',
      429 => 'محدودیت درخواست یا اعتبار سرویس‌دهنده تمام شده است.',
      >= 500 => 'سرویس‌دهنده هوش مصنوعی با خطا مواجه شد. بعداً تلاش کنید.',
      _ => 'خطای سرویس‌دهنده هوش مصنوعی (کد $statusCode).',
    };
  }
  final text = error.toString().toLowerCase();
  if (text.contains('timeout')) {
    return 'زمان انتظار برای پاسخ سرویس‌دهنده تمام شد.';
  }
  if (text.contains('cancel')) return 'درخواست لغو شد.';
  if (kIsWeb) {
    return 'اتصال از مرورگر به سرویس‌دهنده برقرار نشد. '
        'ممکن است سرویس‌دهنده درخواست‌های مرورگر (CORS) را مجاز نکرده باشد '
        'یا آدرس/کلید اشتباه باشد.';
  }
  if (text.contains('socket') ||
      text.contains('connection') ||
      text.contains('network')) {
    return 'اتصال به سرویس‌دهنده هوش مصنوعی برقرار نشد. اتصال اینترنت را بررسی کنید.';
  }
  if (text.contains('certificate')) {
    return 'گواهی امنیتی سرویس‌دهنده معتبر نیست.';
  }
  return 'ارتباط با سرویس‌دهنده هوش مصنوعی ناموفق بود.';
}
