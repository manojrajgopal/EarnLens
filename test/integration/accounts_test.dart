import 'package:earnlens/core/clock.dart';
import 'package:earnlens/core/date_time/local_date.dart';
import 'package:earnlens/core/errors/app_exception.dart';
import 'package:earnlens/data/repositories/local_account_repository.dart';
import 'package:earnlens/data/repositories/local_earnings_data_source.dart';
import 'package:earnlens/data/repositories/local_income_source_repository.dart';
import 'package:earnlens/data/repositories/local_records_repository.dart';
import 'package:earnlens/database/app_database.dart';
import 'package:earnlens/domain/calculation/earnings_calculator.dart';
import 'package:earnlens/domain/models/account.dart';
import 'package:earnlens/domain/models/enums.dart';
import 'package:earnlens/domain/models/income_source.dart';
import 'package:earnlens/domain/money/fraction.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_database.dart';

void main() {
  final clock = FixedClock(DateTime.utc(2024, 6, 15, 6));
  final cal = calendarFor('Asia/Kolkata');
  final calc = EarningsCalculator(engineFor());
  final now = at(cal, 2024, 6, 15, 12);
  final june = DateRange.month(YearMonth(2024, 6));

  late AppDatabase db;
  late SeqIds ids;
  late LocalAccountRepository accounts;
  late LocalCombinedAccountRepository combined;

  Account account(String id, {String name = 'Account', String currency = 'INR'}) => Account(
        id: id,
        name: name,
        type: AccountType.personal,
        currencyCode: currency,
        createdAt: clock.now(),
        updatedAt: clock.now(),
      );

  CombinedAccount combo(String id, List<String> members, {String name = 'Household', String currency = 'INR'}) =>
      CombinedAccount(
        id: id,
        name: name,
        currencyCode: currency,
        memberIds: members,
        createdAt: clock.now(),
        updatedAt: clock.now(),
      );

  LocalIncomeSourceRepository sourcesOf(String accountId) =>
      LocalIncomeSourceRepository(db, clock, ids, AccountScope.single(accountId));
  LocalRecordsRepository recordsOf(String accountId) =>
      LocalRecordsRepository(db, clock, ids, AccountScope.single(accountId));

  /// A monthly salary source in [accountId].
  Future<void> salary(String accountId, String sourceId, int monthlyMinor, {String currency = 'INR'}) {
    final s = source(id: sourceId, start: d(2024, 1, 1), currency: currency);
    return sourcesOf(accountId).createSource(s, initialRate: rev(sourceId, s.startDate, monthlyMinor));
  }

  Future<Fraction> earnedInJune(Set<String> accountIds, {String currency = 'INR'}) async {
    final snap = await LocalEarningsDataSource(db, accountIds).loadSnapshot();
    return calc.liveTotal(snap, june, now, currencyCode: currency);
  }

  Future<int> rowCount() async {
    var n = 0;
    for (final t in db.tablesInInsertOrder) {
      if (t == db.auditLog || t == db.settings) continue;
      n += (await db.select(t).get()).length;
    }
    return n;
  }

  setUp(() async {
    db = memoryDatabase();
    ids = SeqIds();
    accounts = LocalAccountRepository(db, clock, ids);
    combined = LocalCombinedAccountRepository(db, clock, ids);
    await accounts.createAccount(account('a', name: 'Asha'));
    await accounts.createAccount(account('b', name: 'Ravi'));
  });

  tearDown(() => db.close());

  group('account limit', () {
    test('allows exactly 10 individual accounts', () async {
      for (var i = 3; i <= 10; i++) {
        await accounts.createAccount(account('acc$i'));
      }
      expect(await accounts.accounts(), hasLength(10));
      await expectLater(accounts.createAccount(account('acc11')), throwsA(isA<AccountLimitException>()));
      expect(await accounts.accounts(), hasLength(10));
    });

    test('the database refuses an 11th account even when inserted directly', () async {
      for (var i = 3; i <= 10; i++) {
        await accounts.createAccount(account('acc$i'));
      }
      await expectLater(
        db.into(db.accounts).insert(accountRow('raw')),
        throwsA(predicate((e) => '$e'.contains('EARNLENS_ACCOUNT_LIMIT'))),
      );
    });

    test('combined accounts do not count toward the limit', () async {
      for (var i = 3; i <= 10; i++) {
        await accounts.createAccount(account('acc$i'));
      }
      await combined.create(combo('c1', ['a', 'b']));
      await combined.create(combo('c2', ['a', 'acc3']));
      expect(await combined.combined(), hasLength(2));
    });

    test('validates names and currency', () async {
      await expectLater(accounts.createAccount(account('x', name: '  ')), throwsA(isA<ValidationException>()));
      await expectLater(accounts.createAccount(account('y', currency: 'rupees')), throwsA(isA<ValidationException>()));
    });
  });

  group('isolation', () {
    test('records of one account never appear in another', () async {
      await salary('a', 'sa', inr(30000));
      await salary('b', 'sb', inr(60000));
      final a = await LocalEarningsDataSource(db, {'a'}).loadSnapshot();
      final b = await LocalEarningsDataSource(db, {'b'}).loadSnapshot();
      expect(a.sources.map((s) => s.id), ['sa']);
      expect(b.sources.map((s) => s.id), ['sb']);
      expect(await sourcesOf('a').source('sb'), isNull);
      expect((await sourcesOf('b').sources()).single.accountId, 'b');
    });

    test('writes are stamped with the open account, whatever the model says', () async {
      final s = IncomeSource(
        id: 'spoof',
        accountId: 'b',
        name: 'Spoof',
        kind: IncomeKind.salary,
        category: IncomeCategory.salary,
        currencyCode: 'INR',
        startDate: d(2024, 1, 1),
        createdAt: clock.now(),
        updatedAt: clock.now(),
      );
      await sourcesOf('a').createSource(s, initialRate: rev('spoof', d(2024, 1, 1), inr(1000)));
      final row = await (db.select(db.incomeSources)..where((t) => t.id.equals('spoof'))).getSingle();
      expect(row.accountId, 'a');
    });

    test("an account cannot change another account's records", () async {
      await salary('a', 'sa', inr(30000));
      final fromB = sourcesOf('b');
      await expectLater(fromB.archiveSource('sa', d(2024, 6, 1)), throwsA(isA<AccountOwnershipException>()));
      await expectLater(
        fromB.addRevision(rev('sa', d(2024, 6, 1), inr(1), type: RevisionChangeType.hike)),
        throwsA(isA<AccountOwnershipException>()),
      );
      await expectLater(
        recordsOf('b').addLedgerEntry(ledger('sa', LedgerType.received, inr(100), YearMonth(2024, 5), d(2024, 6, 1))),
        throwsA(isA<AccountOwnershipException>()),
      );
      expect((await sourcesOf('a').source('sa'))!.status, SourceStatus.active);
    });

    test('combined (read-only) scopes refuse every write', () async {
      await salary('a', 'sa', inr(30000));
      final ro = LocalIncomeSourceRepository(db, clock, ids, AccountScope.readOnly({'a', 'b'}));
      final rro = LocalRecordsRepository(db, clock, ids, AccountScope.readOnly({'a', 'b'}));
      expect((await ro.sources()).map((s) => s.id), ['sa']);
      await expectLater(ro.archiveSource('sa', d(2024, 6, 1)), throwsA(isA<ReadOnlyViewException>()));
      await expectLater(
        rro.addLedgerEntry(ledger('sa', LedgerType.received, inr(100), YearMonth(2024, 5), d(2024, 6, 1))),
        throwsA(isA<ReadOnlyViewException>()),
      );
    });

    test('the database refuses a record whose account differs from its source', () async {
      await salary('a', 'sa', inr(30000));
      await expectLater(
        db.customStatement(
          "INSERT INTO ledger_entries (id, account_id, source_id, type, amount_minor, currency_code, period_month, "
          "date, status, created_at, updated_at) VALUES ('x', 'b', 'sa', 'received', 1, 'INR', '2024-05', "
          "'2024-06-01', 'completed', 0, 0)",
        ),
        throwsA(predicate((e) => '$e'.contains('EARNLENS_ACCOUNT_MISMATCH'))),
      );
      await expectLater(
        db.customStatement("UPDATE income_sources SET account_id = 'b' WHERE id = 'sa'"),
        throwsA(anything),
      );
    });

    test('an "all sources" holiday only applies inside its own account', () async {
      final s = source(id: 'hb', start: d(2024, 1, 1), policy: AccrualPolicy.workingDay);
      await sourcesOf('b').createSource(s, initialRate: rev('hb', s.startDate, inr(22000)));
      await sourcesOf('a').addOverride(
          DayOverride(id: 'hol', date: d(2024, 6, 3), type: DayOverrideType.holiday));
      final combinedSnap = await LocalEarningsDataSource(db, {'a', 'b'}).loadSnapshot();
      expect(combinedSnap.rules['hb']!.isHoliday(d(2024, 6, 3)), isFalse);
      expect(await earnedInJune({'a', 'b'}), await earnedInJune({'b'}));
    });
  });

  group('combined accounts', () {
    test('the same members in a different order are a duplicate', () async {
      await combined.create(combo('c1', ['a', 'b'], name: 'Home'));
      await expectLater(
        combined.create(combo('c2', ['b', 'a'])),
        throwsA(isA<DuplicateCombinationException>()
            .having((e) => e.existingId, 'existingId', 'c1')
            .having((e) => e.existingName, 'existingName', 'Home')),
      );
      expect((await combined.findByMembers(['b', 'a']))!.id, 'c1');
      expect(await combined.combined(), hasLength(1));
    });

    test('rejects invalid member selections', () async {
      Future<void> bad(List<String> members) =>
          expectLater(combined.create(combo('cx', members)), throwsA(isA<ValidationException>()));
      await bad(['a']); // fewer than two
      await bad(['a', 'a']); // same account twice
      await bad(['a', 'missing']); // unknown account
      await combined.create(combo('c1', ['a', 'b']));
      await bad(['a', 'c1']); // a combined account as a member
      await bad(['cx', 'a', 'b']); // itself
    });

    test('totals equal the sum of the members and recalculate after a salary change', () async {
      await salary('a', 'sa', inr(30000));
      await salary('b', 'sb', inr(60000));
      await combined.create(combo('c1', ['a', 'b']));
      final members = (await combined.byId('c1'))!.memberIds.toSet();
      final sum = await earnedInJune({'a'}) + await earnedInJune({'b'});
      expect(await earnedInJune(members), sum);

      await sourcesOf('a').addRevision(rev('sa', d(2024, 6, 1), inr(45000), type: RevisionChangeType.hike));
      final after = await earnedInJune({'a'}) + await earnedInJune({'b'});
      expect(await earnedInJune(members), after);
      expect(after > sum, isTrue);
    });

    test('creating a combined account copies no records', () async {
      await salary('a', 'sa', inr(30000));
      await salary('b', 'sb', inr(60000));
      final financial = (await db.select(db.incomeSources).get()).length + (await db.select(db.rateRevisions).get()).length;
      await combined.create(combo('c1', ['a', 'b']));
      expect((await db.select(db.incomeSources).get()).length + (await db.select(db.rateRevisions).get()).length,
          financial);
    });

    test('adding and removing members recalculates totals', () async {
      await accounts.createAccount(account('c'));
      await salary('a', 'sa', inr(30000));
      await salary('b', 'sb', inr(60000));
      await salary('c', 'sc', inr(90000));
      await combined.create(combo('k', ['a', 'b']));
      await combined.setMembers('k', ['a', 'b', 'c']);
      var members = (await combined.byId('k'))!.memberIds.toSet();
      expect(members, {'a', 'b', 'c'});
      expect(await earnedInJune(members), await earnedInJune({'a'}) + await earnedInJune({'b'}) + await earnedInJune({'c'}));
      await combined.setMembers('k', ['a', 'c']);
      members = (await combined.byId('k'))!.memberIds.toSet();
      expect(members, {'a', 'c'});
      expect(await earnedInJune(members), await earnedInJune({'a'}) + await earnedInJune({'c'}));
    });

    test('member changes cannot create a duplicate set', () async {
      await accounts.createAccount(account('c'));
      await combined.create(combo('k1', ['a', 'b']));
      await combined.create(combo('k2', ['a', 'c']));
      await expectLater(combined.setMembers('k2', ['b', 'a']), throwsA(isA<DuplicateCombinationException>()));
      expect((await combined.byId('k2'))!.memberIds, ['a', 'c']);
    });

    test('deleting a combined account keeps every member record', () async {
      await salary('a', 'sa', inr(30000));
      await salary('b', 'sb', inr(60000));
      await combined.create(combo('c1', ['a', 'b']));
      final before = await rowCount();
      await combined.delete('c1');
      expect(await combined.combined(), isEmpty);
      expect(await rowCount(), before - 3); // the combined row and its two memberships
      expect(await accounts.accounts(), hasLength(2));
      expect((await sourcesOf('a').sources()).single.id, 'sa');
    });

    test('never adds amounts in another currency', () async {
      await salary('a', 'sa', inr(30000));
      await salary('b', 'usd', 500000, currency: 'USD');
      await combined.create(combo('c1', ['a', 'b']));
      expect(await earnedInJune({'a', 'b'}), await earnedInJune({'a'}));
      expect(await earnedInJune({'a', 'b'}, currency: 'USD'), await earnedInJune({'b'}, currency: 'USD'));
    });
  });

  group('deleting an account', () {
    test('removes only its own records and settings', () async {
      await salary('a', 'sa', inr(30000));
      await salary('b', 'sb', inr(60000));
      await recordsOf('a').addLedgerEntry(
          ledger('sa', LedgerType.received, inr(30000), YearMonth(2024, 5), d(2024, 6, 1)));
      await db.into(db.settings).insert(SettingRow(key: 'dashboard@a', value: '{}', updatedAt: 0));
      await db.into(db.settings).insert(SettingRow(key: 'dashboard@b', value: '{}', updatedAt: 0));
      final bBefore = await earnedInJune({'b'});

      final preview = await accounts.previewDelete('a');
      expect(preview.sourceCount, 1);
      expect(preview.recordCount, 2); // the starting rate and the payment
      await accounts.deleteAccount('a');

      expect((await accounts.accounts()).map((a) => a.id), ['b']);
      expect((await db.select(db.incomeSources).get()).map((s) => s.id), ['sb']);
      expect(await db.select(db.ledgerEntries).get(), isEmpty);
      expect(await earnedInJune({'b'}), bBefore);
      final keys = (await db.select(db.settings).get()).map((s) => s.key);
      expect(keys, contains('dashboard@b'));
      expect(keys, isNot(contains('dashboard@a')));
    });

    test('drops combined accounts left with one member and keeps the rest', () async {
      await accounts.createAccount(account('c'));
      await combined.create(combo('ab', ['a', 'b']));
      await combined.create(combo('abc', ['a', 'b', 'c']));
      final impact = await accounts.previewDelete('a');
      expect(impact.removedCombined.map((c) => c.id), ['ab']);
      expect(impact.updatedCombined.map((c) => c.id), ['abc']);
      await accounts.deleteAccount('a');
      final left = await combined.combined();
      expect(left.single.id, 'abc');
      expect(left.single.memberIds, ['b', 'c']);
      expect(left.single.memberKey, 'b,c');
    });

    test('drops a combined account that would duplicate another', () async {
      await accounts.createAccount(account('c'));
      await combined.create(combo('bc', ['b', 'c']));
      await combined.create(combo('abc', ['a', 'b', 'c']));
      final impact = await accounts.deleteAccount('a');
      expect(impact.removedCombined.map((c) => c.id), ['abc']);
      expect((await combined.combined()).single.id, 'bc');
    });

    test('the last account cannot be deleted', () async {
      await accounts.deleteAccount('b');
      await expectLater(accounts.deleteAccount('a'), throwsA(isA<ValidationException>()));
      expect(await accounts.accounts(), hasLength(1));
    });
  });
}

AccountRow accountRow(String id) => AccountRow(
      id: id,
      name: id,
      type: 'custom',
      colorIndex: 0,
      currencyCode: 'INR',
      requiresPin: false,
      isArchived: false,
      sortOrder: 0,
      createdAt: 0,
      updatedAt: 0,
    );
