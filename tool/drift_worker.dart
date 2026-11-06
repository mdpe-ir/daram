// Web worker for drift's WASM database.
//
// Compile from the project root with:
//   dart compile js -O4 tool/drift_worker.dart -o web/drift_worker.js
//
// It must be compiled with the same `sqlite3` version used by the app so that
// the JS loader provides all imports expected by `sqlite3.wasm`.
import 'package:drift/wasm.dart';

void main() {
  WasmDatabase.workerMainForOpen();
}
