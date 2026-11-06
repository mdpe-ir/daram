import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores the AI provider key outside the app preferences.
abstract interface class ApiKeyStore {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> delete();
}

/// `flutter_secure_storage` backed implementation (Keychain / Keystore).
class SecureApiKeyStore implements ApiKeyStore {
  SecureApiKeyStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _key = 'daram.ai.api_key';

  @override
  Future<String?> read() async {
    try {
      return await _storage.read(key: _key);
    } on Object {
      // A locked keyring must not brick the settings screen; the provider
      // simply shows as "not configured" and asks for the key again.
      return null;
    }
  }

  @override
  Future<void> write(String value) => _storage.write(key: _key, value: value);

  @override
  Future<void> delete() => _storage.delete(key: _key);
}

/// In-memory implementation used by tests and as a safe fallback.
class MemoryApiKeyStore implements ApiKeyStore {
  MemoryApiKeyStore([this._value]);

  String? _value;

  @override
  Future<String?> read() async => _value;

  @override
  Future<void> write(String value) async => _value = value;

  @override
  Future<void> delete() async => _value = null;
}
