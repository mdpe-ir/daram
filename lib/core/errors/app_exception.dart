/// A failure that can be shown to the user directly in Persian.
///
/// Technical details are kept in [debugDetail] and never logged with secrets.
class AppException implements Exception {
  const AppException(this.message, {this.code, this.debugDetail});

  final String message;
  final String? code;
  final String? debugDetail;

  @override
  String toString() => 'AppException($code): $message';
}

/// The user asked for something that cannot be persisted safely.
class ValidationException extends AppException {
  const ValidationException(super.message, {super.code, super.debugDetail});
}

/// A record referenced by an operation does not exist (or is archived).
class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.code, super.debugDetail});
}
