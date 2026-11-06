import 'package:drift/drift.dart';
import 'package:drift/native.dart';

/// Native (Android, iOS, Linux, macOS, Windows) in-memory executor for tests.
QueryExecutor createMemoryExecutor() => NativeDatabase.memory();
