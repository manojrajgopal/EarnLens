import 'package:drift_dev/api/migrations_native.dart';
import 'package:earnlens/core/clock.dart';
import 'package:earnlens/data/local/mappers.dart';
import 'package:earnlens/domain/models/enums.dart';
import 'package:earnlens/data/repositories/local_earnings_data_source.dart';
import 'package:earnlens/data/repositories/local_income_source_repository.dart';
import 'package:earnlens/database/app_database.dart';
import 'package:earnlens/domain/models/account.dart';
import 'package:flutter_test/flutter_test.dart';

import '../generated_migrations/schema.dart';
import '../generated_migrations/schema_v1.dart' as v1;
import '../helpers/fixtures.dart';
import '../helpers/test_database.dart';

/// Verifies the live schema against the saved schema snapshots in
/// drift_schemas/. When bumping schemaVersion:
///   dart run drift_dev schema dump lib/database/app_database.dart drift_schemas/drift_schema_vN.json
///   dart run drift_dev schema generate --data-classes --companions drift_schemas/ test/generated_migrations/
/// then add a `migrateAndValidate(db, N)` case starting from N-1 with data.
void main() {
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('fresh database matches schema v2', () async {
    final connection = await verifier.startAt(2);
    final db = AppDatabase(connection);
    await verifier.migrateAndValidate(db, 2);
    await db.close();
  });

  test('empty v1 database upgrades to v2 without creating an account', () async {
    final schema = await verifier.schemaAt(1);
    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 2);
    expect(await db.select(db.accounts).get(), isEmpty);
    await db.close();
  });

  group('v1 → v2 with data', () {
    late AppDatabase db;

    setUp(() async {
      final schema = await verifier.schemaAt(1);
      final old = v1.DatabaseAtV1(schema.newConnection());
      await old.into(old.profiles).insert(v1.ProfilesCompanion.insert(
            displayName: 'Asha',
            currencyCode: 'INR',
            locale: 'en_IN',
            timezone: 'Asia/Kolkata',
            createdAt: 1,
            updatedAt: 1,
          ));
      for (final key in ['dashboard', 'notifications', 'calculation', 'security', 'appearance']) {
        await old.into(old.settings).insert(v1.SettingsCompanion.insert(key: key, value: '{"k":"$key"}', updatedAt: 1));
      }
      await old.into(old.incomeSources).insert(v1.IncomeSourcesCompanion.insert(
            id: 'sal',
            name: 'Salary',
            kind: 'salary',
            category: 'salary',
            status: 'active',
            currencyCode: 'INR',
            startDate: '2024-01-01',
            accrualPolicy: 'calendarDay',
            workWeekdayMask: 31,
            workStartMinute: 540,
            workEndMinute: 1080,
            payRule: 'dayOfMonth',
            payDay: 1,
            payOffsetMonths: 1,
            weekendAdjust: 'none',
            fixedTotalAccrual: 'spreadCalendarDays',
            forecastMethod: 'estimate',
            createdAt: 1,
            updatedAt: 1,
          ));
      await old.into(old.rateRevisions).insert(v1.RateRevisionsCompanion.insert(
            id: 'r1',
            sourceId: 'sal',
            effectiveFrom: '2024-01-01',
            amountMinor: 3100000,
            period: 'month',
            changeType: 'initial',
            createdAt: 1,
          ));
      await old.into(old.ledgerEntries).insert(v1.LedgerEntriesCompanion.insert(
            id: 'l1',
            sourceId: 'sal',
            type: 'received',
            amountMinor: 3100000,
            currencyCode: 'INR',
            periodMonth: '2024-01',
            date: '2024-02-01',
            status: 'completed',
            createdAt: 1,
            updatedAt: 1,
          ));
      await old.into(old.dayOverrides).insert(v1.DayOverridesCompanion.insert(id: 'h1', date: '2024-01-26', type: 'holiday'));
      await old.into(old.auditLog).insert(v1.AuditLogCompanion.insert(
            id: 'a1',
            entityType: 'source',
            entityId: 'sal',
            action: 'create',
            summary: 'Added',
            at: 1,
          ));
      await old.close();

      db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 2);
    });

    tearDown(() => db.close());

    test('creates one Personal account in the profile currency', () async {
      final accounts = await db.select(db.accounts).get();
      expect(accounts, hasLength(1));
      expect(accounts.single.name, 'Personal');
      expect(accounts.single.type, AccountType.personal.name);
      expect(accounts.single.currencyCode, 'INR');
    });

    test('keeps every record and assigns it to that account', () async {
      final id = (await db.select(db.accounts).getSingle()).id;
      expect((await db.select(db.incomeSources).getSingle()).accountId, id);
      expect((await db.select(db.rateRevisions).getSingle()).accountId, id);
      expect((await db.select(db.ledgerEntries).getSingle()).accountId, id);
      expect((await db.select(db.dayOverrides).getSingle()).accountId, id);
      expect((await db.select(db.auditLog).getSingle()).accountId, id);
      final ledger = await db.select(db.ledgerEntries).getSingle();
      expect(ledger.amountMinor, 3100000);
    });

    test('moves per-account settings and opens the account', () async {
      final id = (await db.select(db.accounts).getSingle()).id;
      final keys = {for (final s in await db.select(db.settings).get()) s.key: s.value};
      expect(keys['dashboard@$id'], '{"k":"dashboard"}');
      expect(keys['notifications@$id'], '{"k":"notifications"}');
      expect(keys['calculation@$id'], '{"k":"calculation"}');
      expect(keys.containsKey('dashboard'), isFalse);
      // App-wide settings stay where they were.
      expect(keys['security'], '{"k":"security"}');
      expect(keys['appearance'], '{"k":"appearance"}');
      expect(keys['activeView'], contains(id));
    });

    test('migrated data still calculates and stays writable', () async {
      final id = (await db.select(db.accounts).getSingle()).id;
      final snap = await LocalEarningsDataSource(db, {id}).loadSnapshot();
      expect(snap.sources.single.id, 'sal');
      expect(snap.rules['sal']!.isHoliday(d(2024, 1, 26)), isTrue);
      final repo = LocalIncomeSourceRepository(db, FixedClock(DateTime.utc(2024, 3)), SeqIds(), AccountScope.single(id));
      await repo.archiveSource('sal', d(2024, 3, 1));
      expect((await repo.source('sal'))!.status, SourceStatus.archived);
    });

    test('ownership triggers are active after the upgrade', () async {
      await db.into(db.accounts).insert(AccountRow(
            id: 'other',
            name: 'Other',
            type: 'family',
            colorIndex: 0,
            currencyCode: 'INR',
            requiresPin: false,
            isArchived: false,
            sortOrder: 1,
            createdAt: 0,
            updatedAt: 0,
          ));
      // A revision cannot point at a source owned by another account.
      await expectLater(
        db.into(db.rateRevisions).insert(RateRevisionRow(
              id: 'bad',
              accountId: 'other',
              sourceId: 'sal',
              effectiveFrom: '2024-02-01',
              amountMinor: 1,
              period: 'month',
              changeType: 'raise',
              createdAt: ts(DateTime.utc(2024))),
            ),
        throwsA(anything),
      );
    });
  });
}
