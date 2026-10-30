import 'package:earnlens/bootstrap/dependency_injection.dart';
import 'package:earnlens/core/clock.dart';
import 'package:earnlens/core/date_time/local_date.dart';
import 'package:earnlens/core/formatting/money_format.dart';
import 'package:earnlens/data/repositories/local_income_source_repository.dart';
import 'package:earnlens/data/repositories/local_records_repository.dart';
import 'package:earnlens/domain/calculation/rate_calculator.dart';
import 'package:earnlens/domain/models/enums.dart';
import 'package:earnlens/domain/models/settings.dart';
import 'package:earnlens/domain/money/currency.dart';
import 'package:earnlens/domain/money/fraction.dart';
import 'package:earnlens/features/dashboard/application/dashboard_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_database.dart';

void main() {
  group('lifetime earnings', () {
    // 15 Oct 2024, 17:30 in India.
    final clock = FixedClock(DateTime.utc(2024, 10, 15, 12));

    Future<ProviderContainer> container() async {
      calendarFor('Asia/Kolkata');
      final db = memoryDatabase();
      final ids = SeqIds();
      await seedAccount(db);
      final s = source(id: 'sal', start: d(2024, 1, 1));
      await LocalIncomeSourceRepository(db, clock, ids, testScope)
          .createSource(s, initialRate: rev('sal', s.startDate, inr(31000)));
      for (final m in [1, 2, 3]) {
        await LocalRecordsRepository(db, clock, ids, testScope)
            .addLedgerEntry(ledger('sal', LedgerType.received, inr(31000), YearMonth(2024, m), d(2024, m + 1, 1)));
      }
      final c = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(clock),
        deviceTimezoneProvider.overrideWithValue('Asia/Kolkata'),
      ]);
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      c.listen(snapshotStreamProvider, (_, _) {});
      await c.read(accountsStreamProvider.future);
      await c.read(combinedAccountsStreamProvider.future);
      await c.read(scopedSnapshotProvider(c.read(accountScopeProvider)).future);
      return c;
    }

    test('completed months add up to the monthly history, from the first income', () async {
      final c = await container();
      final h = c.read(lifetimeHistoryProvider);
      expect(h.since, d(2024, 1, 1));
      expect(h.sourceCount, 1);
      // January–September at ₹31,000 a month.
      expect(h.earned, Fraction.fromInt(inr(31000) * 9));
      expect(h.earnedThisYear, h.earned);
      expect(h.received, inr(31000) * 3);

      final calc = c.read(earningsCalculatorProvider);
      final now = clock.now().microsecondsSinceEpoch;
      final series = calc.monthlySeries(c.read(snapshotProvider), YearMonth(2024, 9), 9, now, currencyCode: 'INR');
      expect(h.earned, Fraction.sum(series.map((m) => m.accrued)));
    });

    test('is empty without income', () async {
      calendarFor('Asia/Kolkata');
      final db = memoryDatabase();
      await seedAccount(db);
      final c = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(clock),
      ]);
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      c.listen(snapshotStreamProvider, (_, _) {});
      await c.read(accountsStreamProvider.future);
      await c.read(combinedAccountsStreamProvider.future);
      await c.read(scopedSnapshotProvider(c.read(accountScopeProvider)).future);
      final h = c.read(lifetimeHistoryProvider);
      expect(h.since, isNull);
      expect(h.earned, Fraction.zero);
    });
  });

  group('dashboard defaults', () {
    test('per second is the default main rate', () {
      final d = DashboardConfig.defaults();
      expect(d.primaryUnit, EarningUnit.second);
      expect(d.units, contains(EarningUnit.second));
    });

    test('lifetime earnings is shown right after the live counter by default', () {
      final types = DashboardConfig.defaults().cards.where((c) => c.visible).map((c) => c.type).toList();
      expect(types.take(2), [DashboardCardType.liveCounter, DashboardCardType.lifetime]);
    });

    test('saved layouts from older versions gain the lifetime card after the counter', () {
      final old = DashboardConfig.defaults().toJson();
      old['cards'] = [
        for (final c in old['cards'] as List)
          if (c['type'] != 'lifetime') c,
      ];
      old['primaryUnit'] = 'day';
      final upgraded = DashboardConfig.fromJson(old);
      expect(upgraded.cards[0].type, DashboardCardType.liveCounter);
      expect(upgraded.cards[1].type, DashboardCardType.lifetime);
      expect(upgraded.cards[1].visible, isTrue);
      // The user's own main rate is kept.
      expect(upgraded.primaryUnit, EarningUnit.day);
    });
  });

  group('small rates', () {
    final money = MoneyFormatter('en_IN', Currency.inr);
    // Paise as a fraction: (numerator, denominator).
    Fraction paise(int n, [int d = 1]) => Fraction.fromInt(n, d);

    test('keep two significant digits', () {
      expect(money.rate(paise(39, 100), decimals: 2), '₹0.0039');
      expect(money.rate(paise(118, 100), decimals: 2), '₹0.012');
      expect(money.rate(paise(28, 10), decimals: 2), '₹0.028');
    });

    test('never show fewer places than the chosen precision', () {
      expect(money.rate(paise(168), decimals: 2), '₹1.68');
      expect(money.rate(paise(118, 100), decimals: 4), '₹0.0118');
      expect(money.rate(Fraction.zero, decimals: 2), '₹0.00');
    });
  });
}
