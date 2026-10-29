import 'package:earnlens/core/clock.dart';
import 'package:earnlens/core/date_time/local_date.dart';
import 'package:earnlens/core/errors/app_exception.dart';
import 'package:earnlens/data/repositories/local_earnings_data_source.dart';
import 'package:earnlens/data/repositories/local_income_source_repository.dart';
import 'package:earnlens/data/repositories/local_profile_settings_repository.dart';
import 'package:earnlens/data/repositories/local_records_repository.dart';
import 'package:earnlens/database/app_database.dart';
import 'package:earnlens/domain/calculation/earnings_calculator.dart';
import 'package:earnlens/domain/models/enums.dart';
import 'package:earnlens/domain/models/income_source.dart';
import 'package:earnlens/domain/models/profile.dart';
import 'package:earnlens/domain/models/records.dart';
import 'package:earnlens/domain/models/settings.dart';
import 'package:earnlens/domain/services/sample_data_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late LocalIncomeSourceRepository sources;
  late LocalRecordsRepository records;
  late LocalEarningsDataSource data;
  final clock = FixedClock(DateTime.utc(2024, 11, 15, 6));
  late SeqIds ids;

  setUp(() {
    db = memoryDatabase();
    ids = SeqIds();
    sources = LocalIncomeSourceRepository(db, clock, ids);
    records = LocalRecordsRepository(db, clock, ids);
    data = LocalEarningsDataSource(db);
  });
  tearDown(() => db.close());

  Future<IncomeSource> addSalary({int monthly = 3100000, LocalDate? start}) async {
    final s = source(id: ids.newId(), start: start ?? d(2024, 1, 1));
    await sources.createSource(s, initialRate: rev(s.id, s.startDate, monthly));
    return s;
  }

  LedgerEntry payment(String sourceId, int amount, YearMonth period, LocalDate date) => LedgerEntry(
        id: ids.newId(),
        sourceId: sourceId,
        type: LedgerType.received,
        amountMinor: amount,
        currencyCode: 'INR',
        periodMonth: period,
        date: date,
        createdAt: clock.now(),
        updatedAt: clock.now(),
      );

  test('database is created with foreign keys enforced', () async {
    final fk = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(fk.data.values.first, 1);
    expect(db.schemaVersion, 1);
  });

  test('profile and settings persist', () async {
    final profiles = LocalProfileRepository(db);
    final settings = LocalSettingsRepository(db, clock);
    await profiles.save(UserProfile(
      displayName: 'Asha',
      currencyCode: 'INR',
      locale: 'en_IN',
      timezone: 'Asia/Kolkata',
      onboardingComplete: true,
      createdAt: clock.now(),
      updatedAt: clock.now(),
    ));
    final cfg = DashboardConfig.defaults().copyWith(precision: 4);
    await settings.write('dashboard', cfg.toJson());
    expect((await profiles.get())!.displayName, 'Asha');
    expect(DashboardConfig.fromJson((await settings.read('dashboard'))!).precision, 4);
  });

  test('source CRUD writes an audit trail', () async {
    final s = await addSalary();
    await sources.updateSource(s.copyWith(name: 'Renamed'));
    expect((await sources.source(s.id))!.name, 'Renamed');
    final audit = await db.select(db.auditLog).get();
    expect(audit.map((a) => a.action), containsAll(['create', 'update']));
  });

  test('validation rejects invalid sources and rolls back', () async {
    final bad = source(id: 'bad', start: d(2024, 5, 1), end: d(2024, 4, 1));
    await expectLater(sources.createSource(bad), throwsA(isA<ValidationException>()));
    expect(await sources.sources(), isEmpty);
  });

  test('REGRESSION: duplicate payments are rejected unless explicitly allowed', () async {
    final s = await addSalary();
    final p = payment(s.id, 3100000, YearMonth(2024, 10), d(2024, 11, 1));
    await records.addLedgerEntry(p);
    final copy = payment(s.id, 3100000, YearMonth(2024, 10), d(2024, 11, 1));
    await expectLater(records.addLedgerEntry(copy), throwsA(isA<DuplicateEntryException>()));
    await records.addLedgerEntry(copy, allowDuplicate: true);
    expect((await db.select(db.ledgerEntries).get()).length, 2);
  });

  test('cancelling a payment frees its duplicate guard', () async {
    final s = await addSalary();
    final p = payment(s.id, 100, YearMonth(2024, 10), d(2024, 11, 1));
    await records.addLedgerEntry(p);
    await records.setLedgerStatus(p.id, LedgerStatus.cancelled);
    await records.addLedgerEntry(payment(s.id, 100, YearMonth(2024, 10), d(2024, 11, 1)));
  });

  test('sources with history cannot be deleted, only archived', () async {
    final s = await addSalary();
    await records.addLedgerEntry(payment(s.id, 100, YearMonth(2024, 10), d(2024, 11, 1)));
    await expectLater(sources.deleteSourceIfUnused(s.id), throwsA(isA<ProtectedHistoryException>()));
    await sources.archiveSource(s.id, d(2024, 11, 15));
    final archived = (await sources.source(s.id))!;
    expect(archived.status, SourceStatus.archived);
    expect(archived.endDate, d(2024, 11, 15));
    expect((await db.select(db.ledgerEntries).get()).length, 1);
  });

  test('the last rate of a source cannot be deleted', () async {
    await addSalary();
    final revs = await db.select(db.rateRevisions).get();
    await expectLater(sources.deleteRevision(revs.single.id), throwsA(isA<ValidationException>()));
  });

  test('pause and resume record a pause interval', () async {
    final s = await addSalary();
    await sources.pauseSource(s.id, d(2024, 6, 11));
    expect((await sources.source(s.id))!.status, SourceStatus.paused);
    await sources.resumeSource(s.id, d(2024, 6, 21));
    final snap = await data.loadSnapshot();
    final calc = EarningsCalculator(engineFor());
    final june = calc.summarize(snap, DateRange.month(YearMonth(2024, 6)), at(calendarFor('Asia/Kolkata'), 2024, 8, 1),
        currencyCode: 'INR');
    expect(june.actual, 2066667); // 20 of 30 days, rounded half-even
    expect(june.expected, 2066667);
  });

  group('monthly records', () {
    test('original estimate is preserved; finalised months need reopening', () async {
      final biz = source(id: 'biz', kind: IncomeKind.variable, start: d(2024, 1, 1));
      await sources.createSource(biz);
      final m = YearMonth(2024, 10);
      MonthlyRecord rec({int? estimate, int? actual}) => MonthlyRecord(
          id: ids.newId(), sourceId: 'biz', month: m, revisedEstimateMinor: estimate, actualMinor: actual, updatedAt: clock.now());

      await records.saveMonthlyRecord(rec(estimate: 2000000));
      await records.saveMonthlyRecord(rec(estimate: 2600000));
      var row = (await db.select(db.monthlyRecords).get()).single;
      expect(row.originalEstimateMinor, 2000000);
      expect(row.revisedEstimateMinor, 2600000);

      await records.finalizeMonth('biz', m, 2450000);
      await expectLater(records.saveMonthlyRecord(rec(estimate: 2600000, actual: 1)), throwsA(isA<ValidationException>()));
      // REGRESSION: editing the estimate keeps the actual.
      await records.saveMonthlyRecord(rec(estimate: 2700000, actual: 2450000));
      row = (await db.select(db.monthlyRecords).get()).single;
      expect(row.actualMinor, 2450000);
      expect(row.revisedEstimateMinor, 2700000);

      // REGRESSION: reopening and correcting recalculates totals.
      await records.reopenMonth('biz', m, 'late invoice');
      await records.saveMonthlyRecord(rec(actual: 2550000));
      final snap = await data.loadSnapshot();
      final oct = EarningsCalculator(engineFor()).summarize(
          snap, DateRange.month(m), at(calendarFor('Asia/Kolkata'), 2024, 11, 15), currencyCode: 'INR');
      expect(oct.actual, 2550000);
      final actions = (await db.select(db.auditLog).get()).map((a) => a.action);
      expect(actions, containsAll(['finalize', 'reopen']));
    });
  });

  test('snapshot stream emits when data changes', () async {
    final stream = data.watchSnapshot();
    final seen = <int>[];
    final sub = stream.listen((s) => seen.add(s.sources.length));
    await pumpEventQueue();
    await addSalary();
    await pumpEventQueue(times: 50);
    await sub.cancel();
    expect(seen.first, 0);
    expect(seen.last, 1);
  });

  test('sample data is flagged and removed completely', () async {
    final real = await addSalary();
    final sample = SampleDataService(sources, records, clock, ids);
    await sample.insert(currencyCode: 'INR', today: d(2024, 11, 15));
    expect((await sources.sources()).where((s) => s.isSample).length, 2);
    await sample.remove();
    final left = await sources.sources();
    expect(left.map((s) => s.id), [real.id]);
    expect(await db.select(db.compensationItems).get(), isEmpty);
    expect(await db.select(db.monthlyRecords).get(), isEmpty);
  });
}
