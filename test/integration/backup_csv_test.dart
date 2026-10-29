import 'dart:convert';
import 'dart:typed_data';

import 'package:earnlens/core/clock.dart';
import 'package:earnlens/core/date_time/local_date.dart';
import 'package:earnlens/core/errors/app_exception.dart';
import 'package:earnlens/data/backup/backup_service.dart';
import 'package:earnlens/data/backup/csv_service.dart';
import 'package:earnlens/data/repositories/local_earnings_data_source.dart';
import 'package:earnlens/data/repositories/local_income_source_repository.dart';
import 'package:earnlens/data/repositories/local_records_repository.dart';
import 'package:earnlens/database/app_database.dart';
import 'package:earnlens/domain/models/enums.dart';
import 'package:earnlens/domain/models/records.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_database.dart';

void main() {
  final clock = FixedClock(DateTime.utc(2024, 11, 15, 6));

  Future<(AppDatabase, String)> seeded() async {
    final db = memoryDatabase();
    final ids = SeqIds();
    final sources = LocalIncomeSourceRepository(db, clock, ids);
    final records = LocalRecordsRepository(db, clock, ids);
    final s = source(id: 'salary');
    await sources.createSource(s, initialRate: rev(s.id, s.startDate, 3100000));
    for (var m = 8; m <= 10; m++) {
      await records.addLedgerEntry(LedgerEntry(
        id: 'pay-$m',
        sourceId: s.id,
        type: LedgerType.received,
        amountMinor: 3100000,
        currencyCode: 'INR',
        periodMonth: YearMonth(2024, m),
        date: LocalDate(2024, m + 1, 1),
        createdAt: clock.now(),
        updatedAt: clock.now(),
      ));
    }
    return (db, s.id);
  }

  BackupService backup(AppDatabase db) => BackupService(db, clock, kdfIterations: 1000);

  group('backup & restore', () {
    test('plain round trip into an empty database', () async {
      final (src, _) = await seeded();
      final bytes = await backup(src).createBackup();
      final dst = memoryDatabase();
      final preview = await backup(dst).inspect(bytes);
      expect(preview.sourceCount, 1);
      expect(preview.ledgerCount, 3);
      final r = await backup(dst).restore(preview, RestoreMode.replace);
      expect(r.inserted, greaterThan(0));
      expect((await dst.select(dst.ledgerEntries).get()).length, 3);
      await src.close();
      await dst.close();
    });

    test('encrypted backups need the right password', () async {
      final (db, _) = await seeded();
      final bytes = await backup(db).createBackup(password: 'correct horse');
      expect(BackupService.isEncrypted(bytes), isTrue);
      expect(utf8.decode(bytes).contains('salary'), isFalse, reason: 'payload must not be readable');
      await expectLater(backup(db).inspect(bytes), throwsA(isA<BackupException>()));
      await expectLater(backup(db).inspect(bytes, password: 'wrong'), throwsA(isA<BackupException>()));
      final preview = await backup(db).inspect(bytes, password: 'correct horse');
      expect(preview.encrypted, isTrue);
      await db.close();
    });

    test('tampered backups are rejected', () async {
      final (db, _) = await seeded();
      final env = jsonDecode(utf8.decode(await backup(db).createBackup())) as Map<String, dynamic>;
      ((env['payload'] as Map)['tables'] as Map)['ledger_entries'][0]['amountMinor'] = 1;
      final tampered = Uint8List.fromList(utf8.encode(jsonEncode(env)));
      await expectLater(backup(db).inspect(tampered), throwsA(isA<BackupException>()));
      await db.close();
    });

    test('non-backup and future-version files are rejected', () async {
      final db = memoryDatabase();
      await expectLater(backup(db).inspect(Uint8List.fromList(utf8.encode('hello'))), throwsA(isA<BackupException>()));
      final future = {'format': BackupService.format, 'formatVersion': 99, 'schemaVersion': 1};
      await expectLater(
          backup(db).inspect(Uint8List.fromList(utf8.encode(jsonEncode(future)))), throwsA(isA<BackupException>()));
      await db.close();
    });

    test('REGRESSION: restoring the same backup twice (merge) never duplicates', () async {
      final (db, _) = await seeded();
      final svc = backup(db);
      final preview = await svc.inspect(await svc.createBackup());
      final r = await svc.restore(preview, RestoreMode.merge);
      expect(r.inserted, 0);
      expect((await db.select(db.ledgerEntries).get()).length, 3);
      await db.close();
    });

    test('REGRESSION: a failed restore leaves existing data untouched', () async {
      final (db, _) = await seeded();
      final svc = backup(db);
      final preview = await svc.inspect(await svc.createBackup());
      // Corrupt the validated preview so an insert fails mid-transaction.
      final broken = BackupPreview(
        createdAt: preview.createdAt,
        schemaVersion: preview.schemaVersion,
        appVersion: preview.appVersion,
        counts: preview.counts,
        encrypted: false,
        tables: {
          ...preview.tables,
          'ledger_entries': [
            ...preview.tables['ledger_entries']!,
            {...preview.tables['ledger_entries']!.first, 'id': 'x', 'sourceId': 'missing', 'dedupeKey': null},
          ],
        },
      );
      await expectLater(svc.restore(broken, RestoreMode.replace), throwsA(anything));
      expect((await db.select(db.ledgerEntries).get()).length, 3);
      expect((await db.select(db.incomeSources).get()).length, 1);
      await db.close();
    });
  });

  group('csv', () {
    test('export then import detects duplicates', () async {
      final (db, _) = await seeded();
      final ids = SeqIds();
      final csv = CsvService(clock, ids);
      final snap = await LocalEarningsDataSource(db).loadSnapshot();
      final text = csv.exportLedger(snap);
      expect(text.split('\r\n').length, 4);
      final report = await csv.importLedger(text, snap, LocalRecordsRepository(db, clock, ids));
      expect(report.errors, isEmpty);
      expect(report.imported, 0);
      expect(report.duplicates, 3);
      await db.close();
    });

    test('invalid lines are reported and nothing is imported', () async {
      final (db, _) = await seeded();
      final ids = SeqIds();
      final csv = CsvService(clock, ids);
      final snap = await LocalEarningsDataSource(db).loadSnapshot();
      const input = 'date,source,type,amount\r\n'
          '2024-11-01,Source salary,received,500\r\n'
          '2024-13-01,Source salary,received,500\r\n'
          '2024-11-02,Unknown,received,500\r\n'
          '2024-11-03,Source salary,bogus,500\r\n'
          '2024-11-04,Source salary,received,abc\r\n';
      final report = await csv.importLedger(input, snap, LocalRecordsRepository(db, clock, ids));
      expect(report.imported, 0);
      expect(report.errors.length, 4);
      expect(report.errors.first, startsWith('Line 3'));
      expect((await db.select(db.ledgerEntries).get()).length, 3);
      await db.close();
    });

    test('quoting and formula-injection protection', () {
      final out = CsvService.encode([
        ['a,b', 'say "hi"', '=SUM(A1)', '-500'],
      ]);
      expect(out, '"a,b","say ""hi""",\'=SUM(A1),-500');
      expect(CsvService.decode(out).single, ['a,b', 'say "hi"', "'=SUM(A1)", '-500']);
    });
  });
}
