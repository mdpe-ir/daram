import 'package:daram/core/services/api_key_store.dart';

/// In-memory API key store for widget tests (no platform channels).
class TestKeyStore implements ApiKeyStore {
  TestKeyStore([this._value]);

  String? _value;

  @override
  Future<void> delete() async => _value = null;

  @override
  Future<String?> read() async => _value;

  @override
  Future<void> write(String value) async => _value = value;
}
