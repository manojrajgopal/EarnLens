import 'package:drift_dev/api/migrations_native.dart';
import 'package:earnlens/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../generated_migrations/schema.dart';

/// Verifies the live schema against the saved schema snapshots in
/// drift_schemas/. When bumping schemaVersion:
///   dart run drift_dev schema dump lib/database/app_database.dart drift_schemas/drift_schema_vN.json
///   dart run drift_dev schema generate drift_schemas/ test/generated_migrations/
/// then add a `migrateAndValidate(db, N)` case starting from N-1 with data.
void main() {
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('fresh database matches schema v1', () async {
    final connection = await verifier.startAt(1);
    final db = AppDatabase(connection);
    await verifier.migrateAndValidate(db, 1);
    await db.close();
  });
}
