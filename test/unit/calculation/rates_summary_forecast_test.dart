import 'package:earnlens/core/date_time/local_date.dart';
import 'package:earnlens/domain/calculation/earnings_calculator.dart';
import 'package:earnlens/domain/calculation/earnings_snapshot.dart';
import 'package:earnlens/domain/calculation/forecast_calculator.dart';
import 'package:earnlens/domain/calculation/payment_schedule.dart';
import 'package:earnlens/domain/calculation/rate_calculator.dart';
import 'package:earnlens/domain/calculation/source_rules.dart';
import 'package:earnlens/domain/calculation/what_if.dart';
import 'package:earnlens/domain/models/enums.dart';
import 'package:earnlens/domain/models/records.dart';
import 'package:earnlens/domain/money/fraction.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';

void main() {
  final engine = engineFor();
  final cal = engine.calendar;
  final calc = EarningsCalculator(engine);
  final rates = RateCalculator(engine);
  final forecaster = ForecastCalculator(calc);

  group('rates', () {
    final s = source();
    final r = SourceRules(source: s, revisions: [rev(s.id, s.startDate, inr(35000))]);

    test('every unit is consistent for a calendar-day salary', () {
      final ref = d(2024, 4, 10); // 30-day month
      expect(rates.rate(r, EarningUnit.month, ref), Fraction.fromInt(inr(35000)));
      expect(rates.rate(r, EarningUnit.day, ref), Fraction.fromInt(inr(35000), 30));
      expect(rates.rate(r, EarningUnit.hour, ref), Fraction.fromInt(inr(35000), 30 * 24));
      expect(rates.rate(r, EarningUnit.minute, ref), Fraction.fromInt(inr(35000), 30 * 24 * 60));
      expect(rates.rate(r, EarningUnit.second, ref), Fraction.fromInt(inr(35000), 30 * 86400));
      expect(rates.rate(r, EarningUnit.quarter, ref), Fraction.fromInt(inr(105000)));
      expect(rates.rate(r, EarningUnit.year, ref), Fraction.fromInt(inr(420000)));
    });

    test('per-second matches the live counter within the day', () {
      final ref = d(2024, 10, 10);
      final perSecond = rates.rate(r, EarningUnit.second, ref);
      final accrued = engine.accruedBetween(r, at(cal, 2024, 10, 10, 10), at(cal, 2024, 10, 10, 11));
      expect(accrued, perSecond.timesInt(3600));
    });

    test('working-time hourly basis uses the schedule', () {
      final w = source(policy: AccrualPolicy.workingDay);
      final wr = SourceRules(source: w, revisions: [rev(w.id, w.startDate, inr(23000))]);
      final ref = d(2024, 10, 1); // 23 working days, 9h days
      expect(rates.rate(wr, EarningUnit.day, ref), Fraction.fromInt(inr(1000)));
      expect(rates.rate(wr, EarningUnit.hour, ref, basis: RateBasis.workingTime), Fraction.fromInt(inr(1000), 9));
      expect(rates.rate(wr, EarningUnit.week, ref), Fraction.fromInt(inr(5000)));
    });

    test('no rate after the end date or while paused', () {
      final ended = source(end: d(2024, 1, 31));
      final er = SourceRules(source: ended, revisions: [rev(ended.id, ended.startDate, inr(1000))]);
      expect(rates.rate(er, EarningUnit.day, d(2024, 2, 1)), Fraction.zero);
    });
  });

  group('payment schedule', () {
    test('salary earned in October is due in November and not before', () {
      final s = source(payDay: 7, payOffsetMonths: 1);
      expect(PaymentScheduler.dueDateFor(s, YearMonth(2024, 10)), d(2024, 11, 7));
      final same = source(payRule: PayRule.lastDayOfMonth, payOffsetMonths: 0);
      expect(PaymentScheduler.dueDateFor(same, YearMonth(2024, 2)), d(2024, 2, 29));
    });

    test('pay day clamps to short months and adjusts for weekends', () {
      final s = source(payDay: 31, payOffsetMonths: 0, weekendAdjust: WeekendAdjust.previousBusinessDay);
      // 2024-11-30 is a Saturday → Friday 29th
      expect(PaymentScheduler.dueDateFor(s, YearMonth(2024, 11)), d(2024, 11, 29));
      final next = source(payDay: 2, payOffsetMonths: 0, weekendAdjust: WeekendAdjust.nextBusinessDay);
      // 2024-11-02 is a Saturday → Monday 4th
      expect(PaymentScheduler.dueDateFor(next, YearMonth(2024, 11)), d(2024, 11, 4));
    });

    test('statuses: received, partial, overdue, upcoming', () {
      final s = source(payDay: 1, payOffsetMonths: 1);
      final rules = [SourceRules(source: s, revisions: [rev(s.id, s.startDate, inr(30000))])];
      final ledgerEntries = [
        ledger(s.id, LedgerType.received, inr(30000), YearMonth(2024, 8), d(2024, 9, 1)),
        ledger(s.id, LedgerType.received, inr(10000), YearMonth(2024, 9), d(2024, 10, 1)),
      ];
      final payments = PaymentScheduler(engine).expectedPayments(
        rules: rules,
        items: const [],
        ledger: ledgerEntries,
        periods: [YearMonth(2024, 8), YearMonth(2024, 9), YearMonth(2024, 10), YearMonth(2024, 11)],
        today: d(2024, 11, 15),
      );
      expect(payments.map((p) => p.status).toList(), [
        PaymentStatus.received,
        PaymentStatus.partiallyReceived,
        PaymentStatus.overdue,
        PaymentStatus.upcoming,
      ]);
    });
  });

  group('summaries', () {
    final s = source(payDay: 1, payOffsetMonths: 1);
    final revisions = [rev(s.id, s.startDate, inr(31000))];

    test('REGRESSION: recording a salary payment does not duplicate earnings', () {
      final before = EarningsSnapshot(sources: [s], revisions: revisions);
      final after = EarningsSnapshot(sources: [s], revisions: revisions, ledger: [
        ledger(s.id, LedgerType.received, inr(31000), YearMonth(2024, 10), d(2024, 11, 1)),
      ]);
      final now = at(cal, 2024, 11, 15);
      final range = DateRange.month(YearMonth(2024, 10));
      final a = calc.summarize(before, range, now, currencyCode: 'INR');
      final b = calc.summarize(after, range, now, currencyCode: 'INR');
      expect(b.actual, a.actual);
      expect(b.actual, inr(31000));
      expect(b.received, inr(31000));
      expect(b.outstanding, 0);
      // The November summary is unaffected by October's payment.
      final nov = calc.summarize(after, DateRange.month(YearMonth(2024, 11)), now, currencyCode: 'INR');
      expect(nov.received, 0);
    });

    test('retroactive adjustment is a separate entry in the period it corrects', () {
      final snap = EarningsSnapshot(sources: [s], revisions: revisions, ledger: [
        ledger(s.id, LedgerType.adjustment, inr(2500), YearMonth(2024, 9), d(2024, 11, 5)),
      ]);
      final now = at(cal, 2024, 11, 15);
      final sep = calc.summarize(snap, DateRange.month(YearMonth(2024, 9)), now, currencyCode: 'INR');
      expect(sep.actual, inr(31000 + 2500));
      expect(sep.expected, inr(31000));
      expect(sep.variance, inr(2500));
    });

    test('deductions and receipts give outstanding', () {
      final snap = EarningsSnapshot(sources: [s], revisions: revisions, ledger: [
        ledger(s.id, LedgerType.deduction, inr(3000), YearMonth(2024, 10), d(2024, 11, 1)),
        ledger(s.id, LedgerType.received, inr(20000), YearMonth(2024, 10), d(2024, 11, 1)),
        ledger(s.id, LedgerType.received, inr(5000), YearMonth(2024, 10), d(2024, 11, 2), status: LedgerStatus.cancelled),
      ]);
      final oct = calc.summarize(snap, DateRange.month(YearMonth(2024, 10)), at(cal, 2024, 11, 15), currencyCode: 'INR');
      expect(oct.outstanding, inr(31000 - 3000 - 20000));
    });

    test('totals never mix currencies', () {
      final usd = source(id: 'usd', currency: 'USD');
      final snap = EarningsSnapshot(sources: [s, usd], revisions: [...revisions, rev('usd', usd.startDate, 100000)]);
      final oct = calc.summarize(snap, DateRange.month(YearMonth(2024, 10)), at(cal, 2024, 11, 1), currencyCode: 'INR');
      expect(oct.sources.length, 1);
    });
  });

  group('variable income', () {
    final biz = source(id: 'biz', kind: IncomeKind.variable, start: d(2024, 1, 1));
    final revisions = [rev('biz', d(2024, 1, 1), inr(20000), type: RevisionChangeType.estimateUpdate)];

    MonthlyRecord record(YearMonth m, {int? original, int? revised, int? actual}) => MonthlyRecord(
          id: 'm${m.toIso()}',
          sourceId: 'biz',
          month: m,
          originalEstimateMinor: original,
          revisedEstimateMinor: revised,
          actualMinor: actual,
          updatedAt: fixedCreated,
        );

    test('expected vs actual variance', () {
      final snap = EarningsSnapshot(sources: [biz], revisions: revisions, monthlyRecords: [
        record(YearMonth(2024, 10), original: inr(20000), actual: inr(24500)),
      ]);
      final oct = calc.summarize(snap, DateRange.month(YearMonth(2024, 10)), at(cal, 2024, 11, 5), currencyCode: 'INR');
      expect(oct.expected, inr(20000));
      expect(oct.actual, inr(24500));
      expect(oct.variance, inr(4500));
    });

    test('REGRESSION: editing an estimate does not overwrite the actual', () {
      final snap = EarningsSnapshot(sources: [biz], revisions: revisions, monthlyRecords: [
        record(YearMonth(2024, 10), original: inr(20000), revised: inr(26000), actual: inr(24500)),
      ]);
      final oct = calc.summarize(snap, DateRange.month(YearMonth(2024, 10)), at(cal, 2024, 11, 5), currencyCode: 'INR');
      expect(oct.expected, inr(26000));
      expect(oct.actual, inr(24500));
    });

    test('monthly total wins over detailed entries — no double counting', () {
      final snap = EarningsSnapshot(
        sources: [biz],
        revisions: revisions,
        monthlyRecords: [record(YearMonth(2024, 10), actual: inr(24500))],
        ledger: [
          ledger('biz', LedgerType.earned, inr(10000), YearMonth(2024, 10), d(2024, 10, 3)),
          ledger('biz', LedgerType.earned, inr(14500), YearMonth(2024, 10), d(2024, 10, 20)),
        ],
      );
      final oct = calc.summarize(snap, DateRange.month(YearMonth(2024, 10)), at(cal, 2024, 11, 5), currencyCode: 'INR');
      expect(oct.actual, inr(24500));
    });

    test('without a monthly total, detailed entries are the actual', () {
      final snap = EarningsSnapshot(sources: [biz], revisions: revisions, ledger: [
        ledger('biz', LedgerType.earned, inr(10000), YearMonth(2024, 10), d(2024, 10, 3)),
        ledger('biz', LedgerType.earned, inr(2000), YearMonth(2024, 10), d(2024, 10, 20)),
      ]);
      final mid = calc.summarize(snap, DateRange.month(YearMonth(2024, 10)), at(cal, 2024, 10, 10), currencyCode: 'INR');
      expect(mid.actual, inr(10000)); // future-dated entry not yet counted
    });

    test('forecast uses actual-so-far floor and estimate', () {
      final snap = EarningsSnapshot(sources: [biz], revisions: revisions, ledger: [
        ledger('biz', LedgerType.earned, inr(25000), YearMonth(2024, 10), d(2024, 10, 3)),
      ]);
      final f = forecaster.forMonth(snap, YearMonth(2024, 10), at(cal, 2024, 10, 10), currencyCode: 'INR');
      expect(f.total, inr(25000)); // already above the ₹20,000 estimate
    });

    test('average forecast method', () {
      final avg = source(id: 'biz', kind: IncomeKind.variable, start: d(2024, 1, 1), forecastMethod: ForecastMethod.average3);
      final snap = EarningsSnapshot(sources: [avg], revisions: revisions, monthlyRecords: [
        record(YearMonth(2024, 7), actual: inr(10000)),
        record(YearMonth(2024, 8), actual: inr(20000)),
        record(YearMonth(2024, 9), actual: inr(30000)),
      ]);
      final f = forecaster.forMonth(snap, YearMonth(2024, 10), at(cal, 2024, 10, 1, 1), currencyCode: 'INR');
      expect(f.total, inr(20000));
    });
  });

  group('compensation items', () {
    final s = source();
    final revisions = [rev(s.id, s.startDate, inr(30000))];

    CompensationItem bonus({int? expected, int? actual, LocalDate? expectedDate, LocalDate? earned, Recurrence rec = Recurrence.none, bool forecast = true}) =>
        CompensationItem(
          id: 'b${expectedDate ?? earned}',
          sourceId: s.id,
          type: CompensationType.annualBonus,
          title: 'Bonus',
          currencyCode: 'INR',
          expectedMinor: expected,
          actualMinor: actual,
          expectedDate: expectedDate,
          earnedDate: earned,
          recurrence: rec,
          includeInForecast: forecast,
          createdAt: fixedCreated,
          updatedAt: fixedCreated,
        );

    test('bonus counts once as earned; its payment does not add again', () {
      final item = bonus(expected: inr(50000), actual: inr(55000), expectedDate: d(2024, 3, 31), earned: d(2024, 3, 31));
      final snap = EarningsSnapshot(sources: [s], revisions: revisions, items: [item], ledger: [
        ledger(s.id, LedgerType.received, inr(55000), YearMonth(2024, 3), d(2024, 4, 10), itemId: item.id),
      ]);
      final mar = calc.summarize(snap, DateRange.month(YearMonth(2024, 3)), at(cal, 2024, 5, 1), currencyCode: 'INR');
      expect(mar.expected, inr(30000 + 50000));
      expect(mar.actual, inr(30000 + 55000));
      expect(mar.received, inr(55000));
    });

    test('recurring bonus projected into future forecasts only', () {
      final item = bonus(expected: inr(12000), expectedDate: d(2024, 3, 15), rec: Recurrence.quarterly);
      final snap = EarningsSnapshot(sources: [s], revisions: revisions, items: [item]);
      final now = at(cal, 2024, 3, 1);
      expect(forecaster.forMonth(snap, YearMonth(2024, 6), now, currencyCode: 'INR').total, inr(42000));
      expect(forecaster.forMonth(snap, YearMonth(2024, 5), now, currencyCode: 'INR').total, inr(30000));
    });

    test('one-time bonus excluded from forecasts when the user says so', () {
      final item = bonus(expected: inr(12000), expectedDate: d(2024, 6, 15), forecast: false);
      final snap = EarningsSnapshot(sources: [s], revisions: revisions, items: [item]);
      expect(forecaster.forMonth(snap, YearMonth(2024, 6), at(cal, 2024, 3, 1), currencyCode: 'INR').total, inr(30000));
    });
  });

  group('year forecast', () {
    test('past months actual + future months projected', () {
      final s = source();
      final snap = EarningsSnapshot(sources: [s], revisions: [
        rev(s.id, s.startDate, inr(30000)),
        rev(s.id, d(2024, 7, 1), inr(40000), type: RevisionChangeType.hike),
      ]);
      final f = forecaster.forYear(snap, 2024, at(cal, 2024, 3, 1), currencyCode: 'INR');
      expect(f.total, inr(30000 * 6 + 40000 * 6));
      expect(f.known, inr(30000 * 2));
    });
  });

  group('what-if', () {
    test('hike, extra income, one-time and hours', () {
      final result = WhatIfCalculator.apply(
        baselineMonthly: inr(50000),
        baselineAnnual: inr(600000),
        changes: [
          HikePercent(currentMonthlyMinor: inr(50000), percentBps: 1000),
          ExtraMonthly(monthlyMinor: inr(5000)),
          OneTimeAmount(inr(20000)),
        ],
      );
      expect(result.newMonthly, inr(60000));
      expect(result.newAnnual, inr(600000 + 60000 + 60000 + 20000));
    });

    test('hours change uses 365.25/7/12 weeks per month', () {
      final result = WhatIfCalculator.apply(
        baselineMonthly: 0,
        baselineAnnual: 0,
        changes: [HoursChange(hourlyRateMinor: inr(100), weeklyHoursDelta: 1000)],
      );
      // 10h × ₹100 × 4.348214… weeks = ₹4,348.21
      expect(result.newMonthly, 434821);
    });
  });
}
