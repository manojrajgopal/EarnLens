import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:earnlens/core/clock.dart';
import 'package:earnlens/database/app_database.dart';
import 'package:earnlens/domain/models/account.dart';

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

/// Id of the individual account most tests write to.
const testAccountId = 'acc-personal';

/// Read/write scope of [testAccountId].
final testScope = AccountScope.single(testAccountId);

/// Inserts an individual account directly (as the v2 migration or onboarding
/// would) unless it exists, and returns its id.
Future<String> seedAccount(
  AppDatabase db, {
  String id = testAccountId,
  String name = 'Personal',
  String currency = 'INR',
  bool requiresPin = false,
}) async {
  final existing = await db.select(db.accounts).get();
  if (existing.any((a) => a.id == id)) return id;
  final order = existing.length;
  await db.into(db.accounts).insert(AccountRow(
        id: id,
        name: name,
        type: 'personal',
        colorIndex: 0,
        currencyCode: currency,
        requiresPin: requiresPin,
        isArchived: false,
        sortOrder: order,
        createdAt: 0,
        updatedAt: 0,
      ));
  return id;
}
