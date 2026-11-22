import 'package:dio/dio.dart';

import 'ai_log_store.dart';

/// Persian label for a transport failure, used as a readable log title.
String dioErrorTypeLabel(DioExceptionType type) => switch (type) {
  DioExceptionType.connectionTimeout => 'زمان اتصال تمام شد',
  DioExceptionType.sendTimeout => 'زمان ارسال درخواست تمام شد',
  DioExceptionType.receiveTimeout => 'زمان انتظار برای پاسخ تمام شد',
  DioExceptionType.transformTimeout => 'زمان تبدیل داده تمام شد',
  DioExceptionType.badCertificate => 'گواهی امنیتی معتبر نیست',
  DioExceptionType.badResponse => 'پاسخ سرویس‌دهنده خطا داشت',
  DioExceptionType.cancel => 'درخواست لغو شد',
  DioExceptionType.connectionError => 'اتصال شبکه برقرار نشد',
  DioExceptionType.unknown => 'خطای نامشخص شبکه',
};

/// Technical context for the diagnostics screen.
///
/// Never includes headers, because they carry the user's API key. The request
/// URL is included: it is the most useful clue when a custom base URL is wrong.
String describeDioException(DioException error) {
  final buffer = StringBuffer()
    ..writeln('type: ${error.type.name}')
    ..writeln('url: ${error.requestOptions.uri}');
  final status = error.response?.statusCode;
  if (status != null) buffer.writeln('status: $status');
  final message = error.message?.trim();
  if (message != null && message.isNotEmpty) {
    buffer.writeln('message: ${truncateText(message, 400)}');
  }
  final data = error.response?.data;
  if (data != null && data is! ResponseBody) {
    final body = data.toString().trim();
    if (body.isNotEmpty) buffer.writeln('body: ${truncateText(body, 400)}');
  }
  return buffer.toString().trim();
}
