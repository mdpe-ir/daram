import 'package:drift/drift.dart';

/// The web uses the WASM database opened by `driftDatabase`; an FFI-backed
/// in-memory database is not available in the browser. Tests that need an
/// in-memory database run on the VM.
QueryExecutor createMemoryExecutor() {
  throw UnsupportedError(
    'NativeDatabase.memory is not available on the web. Use AppDatabase.production().',
  );
}
