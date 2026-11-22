import 'package:daram/core/services/api_key_store.dart';

/// In-memory API key store for widget tests (no platform channels).
class TestKeyStore implements ApiKeyStore {
  TestKeyStore([String? value]) {
    if (value != null) _values[''] = value;
  }

  final Map<String, String> _values = <String, String>{};

  String _slot(String? scope) => (scope ?? '').trim();

  @override
  Future<void> delete({String? scope}) async {
    _values.remove(_slot(scope));
  }

  @override
  Future<String?> read({String? scope}) async => _values[_slot(scope)];

  @override
  Future<void> write(String value, {String? scope}) async {
    _values[_slot(scope)] = value;
  }
}
