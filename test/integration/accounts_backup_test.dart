import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:earnlens/core/clock.dart';
import 'package:earnlens/core/errors/app_exception.dart';
import 'package:earnlens/data/backup/backup_service.dart';
import 'package:earnlens/data/repositories/local_account_repository.dart';
import 'package:earnlens/data/repositories/local_income_source_repository.dart';
import 'package:earnlens/database/app_database.dart';
import 'package:earnlens/domain/models/account.dart';
import 'package:earnlens/domain/models/enums.dart';
import 'package:earnlens/domain/models/settings.dart';
import 'package:earnlens/features/notifications/application/notification_service.dart';
import 'package:earnlens/features/notifications/domain/notification_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_database.dart';

void main() {
  final clock = FixedClock(DateTime.utc(2024, 11, 15, 6));
  BackupService backup(AppDatabase db) => BackupService(db, clock, kdfIterations: 1000);

  /// Two accounts with one salary each, combined, with per-account settings.
  Future<AppDatabase> seeded() async {
    final db = memoryDatabase();
    final ids = SeqIds();
    await seedAccount(db);
    await seedAccount(db, id: 'acc-family', name: 'Family', requiresPin: true);
    for (final (account, id) in [(testAccountId, 'sal'), ('acc-family', 'fam')]) {
      final s = source(id: id, start: d(2024, 1, 1));
      await LocalIncomeSourceRepository(db, clock, ids, AccountScope.single(account))
          .createSource(s, initialRate: rev(id, s.startDate, 3100000));
    }
    await LocalCombinedAccountRepository(db, clock, ids).create(CombinedAccount(
      id: 'home',
      name: 'Home',
      currencyCode: 'INR',
      memberIds: const ['acc-family', testAccountId],
      createdAt: clock.now(),
      updatedAt: clock.now(),
    ));
    await db.into(db.settings).insert(SettingRow(key: 'dashboard@acc-family', value: '{"precision":4}', updatedAt: 0));
    return db;
  }

  test('backups include accounts, combined accounts and memberships', () async {
    final src = await seeded();
    final preview = await backup(src).inspect(await backup(src).createBackup());
    expect(preview.accountCount, 2);
    expect(preview.combinedCount, 1);
    expect(preview.counts['combined_account_members'], 2);

    final dst = memoryDatabase();
    await backup(dst).restore(preview, RestoreMode.replace);
    final combined = await LocalCombinedAccountRepository(dst, clock, SeqIds()).combined();
    expect(combined.single.memberIds, ['acc-family', testAccountId]);
    final sources = await dst.select(dst.incomeSources).get();
    expect({for (final s in sources) s.id: s.accountId}, {'sal': testAccountId, 'fam': 'acc-family'});
    expect((await dst.select(dst.settings).get()).map((s) => s.key), contains('dashboard@acc-family'));
    // Account PINs are never in a backup, so restored accounts start unprotected.
    expect((await dst.select(dst.accounts).get()).every((a) => !a.requiresPin), isTrue);
    await src.close();
    await dst.close();
  });

  test('a backup whose record belongs to a different account than its source is rejected', () async {
    final db = await seeded();
    final env = jsonDecode(utf8.decode(await backup(db).createBackup())) as Map<String, dynamic>;
    final tables = (env['payload'] as Map)['tables'] as Map;
    final revisions = tables['rate_revisions'] as List;
    (revisions.firstWhere((r) => r['sourceId'] == 'sal') as Map)['accountId'] = 'acc-family';
    // Re-sign so only the account check can fail.
    final payload = jsonEncode(env['payload']);
    env['sha256'] = await _sha(payload);
    await expectLater(
      backup(db).inspect(Uint8List.fromList(utf8.encode(jsonEncode(env)))),
      throwsA(isA<BackupException>().having((e) => e.message, 'message', contains('another account'))),
    );
    await db.close();
  });

  test('merging stays within 10 accounts and keeps existing combinations', () async {
    final src = await seeded();
    final preview = await backup(src).inspect(await backup(src).createBackup());
    final dst = memoryDatabase();
    for (var i = 1; i <= 9; i++) {
      await seedAccount(dst, id: 'other-$i');
    }
    await expectLater(backup(dst).restore(preview, RestoreMode.merge), throwsA(isA<BackupException>()));
    expect((await dst.select(dst.accounts).get()).length, 9);

    // Merging into the same data adds nothing and duplicates nothing.
    final again = await backup(src).restore(preview, RestoreMode.merge);
    expect(again.inserted, 0);
    expect((await src.select(src.combinedAccounts).get()).length, 1);
    await src.close();
    await dst.close();
  });

  test('version 1 backups are imported into one Personal account', () async {
    final payload = {
      'tables': {
        'profiles': [
          {
            'id': 1,
            'displayName': 'Asha',
            'currencyCode': 'INR',
            'locale': 'en_IN',
            'timezone': 'Asia/Kolkata',
            'dateOfBirth': null,
            'onboardingComplete': true,
            'createdAt': 0,
            'updatedAt': 0,
          },
        ],
        'settings': [
          {'key': 'dashboard', 'value': '{}', 'updatedAt': 0},
          {'key': 'security', 'value': '{}', 'updatedAt': 0},
        ],
        'income_sources': [_v1Source('sal')],
        'rate_revisions': [
          {
            'id': 'r1',
            'sourceId': 'sal',
            'effectiveFrom': '2024-01-01',
            'amountMinor': 3100000,
            'period': 'month',
            'changeType': 'initial',
            'note': null,
            'createdAt': 0,
          },
        ],
      },
    };
    final payloadJson = jsonEncode(payload);
    final env = {
      'format': BackupService.format,
      'formatVersion': 1,
      'schemaVersion': 1,
      'appVersion': '0.1.0',
      'createdAt': '2024-11-01T00:00:00Z',
      'counts': {},
      'sha256': await _sha(payloadJson),
      'payload': payload,
    };
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(env)));
    final db = memoryDatabase();
    final svc = backup(db);
    await svc.restore(await svc.inspect(bytes), RestoreMode.replace);
    final account = await db.select(db.accounts).getSingle();
    expect(account.name, 'Personal');
    expect((await db.select(db.incomeSources).getSingle()).accountId, account.id);
    expect((await db.select(db.rateRevisions).getSingle()).accountId, account.id);
    final keys = (await db.select(db.settings).get()).map((s) => s.key).toSet();
    expect(keys, {'dashboard@${account.id}', 'security'});

    // The same file again merges into the same account (id derived from the file).
    await svc.restore(await svc.inspect(bytes), RestoreMode.merge);
    expect((await db.select(db.accounts).get()).length, 1);
    await db.close();
  });

  group('notifications', () {
    final at = DateTime.utc(2024, 11, 20).microsecondsSinceEpoch;
    final reminder = PlannedNotification(
      key: 'salary:sal:2024-11:due',
      category: NotificationCategory.salaryPayday,
      title: 'Payday: Acme',
      body: 'Expected ₹31,000.00 today',
      atMicros: at,
      route: '/income/sal',
    );
    Account account({bool pin = false}) => Account(
          id: 'acc-family',
          name: 'Family',
          type: AccountType.family,
          currencyCode: 'INR',
          requiresPin: pin,
          createdAt: clock.now(),
          updatedAt: clock.now(),
        );

    test('reminders are keyed per account and open that account', () {
      final n = NotificationService.forAccount(reminder, account(), labelled: true);
      expect(n.key, 'acc-family|${reminder.key}');
      expect(n.title, 'Payday: Acme · Family');
      expect(n.body, reminder.body);
      expect(Uri.parse(n.route).queryParameters['account'], 'acc-family');
      expect(Uri.parse(n.route).path, '/income/sal');
    });

    test('reminders of a PIN-protected account reveal no names or amounts', () {
      final n = NotificationService.forAccount(reminder, account(pin: true), labelled: true);
      expect(n.title, isNot(contains('Acme')));
      expect(n.body, isNot(contains('31,000')));
      expect(n.title, isNot(contains('Family')));
    });
  });

  test('deleting a protected account through the repository leaves the other untouched', () async {
    final db = await seeded();
    await LocalAccountRepository(db, clock, const UuidGenerator()).deleteAccount('acc-family');
    expect((await db.select(db.incomeSources).get()).map((s) => s.id), ['sal']);
    await expectLater(
      LocalAccountRepository(db, clock, const UuidGenerator()).deleteAccount(testAccountId),
      throwsA(isA<ValidationException>()),
    );
    await db.close();
  });
}

Map<String, dynamic> _v1Source(String id) => {
      'id': id,
      'name': 'Salary',
      'kind': IncomeKind.salary.name,
      'category': 'salary',
      'customCategory': null,
      'status': 'active',
      'currencyCode': 'INR',
      'startDate': '2024-01-01',
      'endDate': null,
      'accrualPolicy': 'calendarDay',
      'workWeekdayMask': 31,
      'workStartMinute': 540,
      'workEndMinute': 1080,
      'payRule': 'dayOfMonth',
      'payDay': 1,
      'payOffsetMonths': 1,
      'weekendAdjust': 'none',
      'expectedPayDate': null,
      'fixedTotalMinor': null,
      'fixedTotalAccrual': 'spreadCalendarDays',
      'forecastMethod': 'estimate',
      'employer': null,
      'takeHomeMinor': null,
      'notes': null,
      'colorIndex': 0,
      'isSample': false,
      'sortOrder': 0,
      'createdAt': 0,
      'updatedAt': 0,
    };

Future<String> _sha(String s) async {
  // Same digest as BackupService (SHA-256 hex of the payload JSON).
  final digest = await _sha256.hash(utf8.encode(s));
  return digest.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

final _sha256 = Sha256();
