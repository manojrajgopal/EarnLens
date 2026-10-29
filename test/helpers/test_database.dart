import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:earnlens/core/clock.dart';
import 'package:earnlens/database/app_database.dart';

AppDatabase memoryDatabase() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

/// Deterministic ids: id-1, id-2, ...
class SeqIds implements IdGenerator {
  int _n = 0;

  @override
  String newId() => 'id-${++_n}';
}
