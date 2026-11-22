import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores the AI provider key outside the app preferences.
///
/// [scope] isolates keys per provider (`openAICompatible`, `openCodeGo`, …), so
/// switching the provider asks for that provider's key instead of silently
/// reusing another one. A null or empty scope is the legacy single-key slot.
abstract interface class ApiKeyStore {
  Future<String?> read({String? scope});
  Future<void> write(String value, {String? scope});
  Future<void> delete({String? scope});
}

/// `flutter_secure_storage` backed implementation (Keychain / Keystore).
class SecureApiKeyStore implements ApiKeyStore {
  SecureApiKeyStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _baseKey = 'daram.ai.api_key';

  String _storageKey(String? scope) {
    final clean = scope?.trim() ?? '';
    return clean.isEmpty ? _baseKey : '$_baseKey.$clean';
  }

  @override
  Future<String?> read({String? scope}) async {
    try {
      return await _storage.read(key: _storageKey(scope));
    } on Object {
      // A locked keyring must not brick the settings screen; the provider
      // simply shows as "not configured" and asks for the key again.
      return null;
    }
  }

  @override
  Future<void> write(String value, {String? scope}) =>
      _storage.write(key: _storageKey(scope), value: value);

  @override
  Future<void> delete({String? scope}) =>
      _storage.delete(key: _storageKey(scope));
}

/// In-memory implementation used by tests and as a safe fallback.
class MemoryApiKeyStore implements ApiKeyStore {
  MemoryApiKeyStore([String? value]) {
    if (value != null) _values[''] = value;
  }

  final Map<String, String> _values = <String, String>{};

  String _slot(String? scope) => (scope ?? '').trim();

  @override
  Future<String?> read({String? scope}) async => _values[_slot(scope)];

  @override
  Future<void> write(String value, {String? scope}) async {
    _values[_slot(scope)] = value;
  }

  @override
  Future<void> delete({String? scope}) async {
    _values.remove(_slot(scope));
  }
}
