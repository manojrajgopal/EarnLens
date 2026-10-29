import 'dart:convert';

import '../../core/clock.dart';
import '../../database/app_database.dart';
import '../../domain/models/profile.dart';
import '../../domain/repositories/repositories.dart';
import '../local/mappers.dart';

class LocalProfileRepository implements ProfileRepository {
  LocalProfileRepository(this.db);
  final AppDatabase db;

  @override
  Future<UserProfile?> get() async => (await db.select(db.profiles).getSingleOrNull())?.toDomain();

  @override
  Stream<UserProfile?> watch() => db.select(db.profiles).watchSingleOrNull().map((r) => r?.toDomain());

  @override
  Future<void> save(UserProfile profile) => db.into(db.profiles).insertOnConflictUpdate(profileToRow(profile));
}

class LocalSettingsRepository implements SettingsRepository {
  LocalSettingsRepository(this.db, this.clock);
  final AppDatabase db;
  final Clock clock;

  @override
  Future<Map<String, dynamic>?> read(String key) async {
    final row = await (db.select(db.settings)..where((t) => t.key.equals(key))).getSingleOrNull();
    return row == null ? null : _decode(row.value);
  }

  @override
  Stream<Map<String, dynamic>?> watch(String key) => (db.select(db.settings)..where((t) => t.key.equals(key)))
      .watchSingleOrNull()
      .map((row) => row == null ? null : _decode(row.value));

  @override
  Future<void> write(String key, Map<String, dynamic> value) => db.into(db.settings).insertOnConflictUpdate(
        SettingsCompanion.insert(key: key, value: jsonEncode(value), updatedAt: ts(clock.now())),
      );

  static Map<String, dynamic>? _decode(String raw) {
    try {
      return (jsonDecode(raw) as Map).cast<String, dynamic>();
    } on Object {
      return null; // corrupted preference falls back to defaults
    }
  }
}
