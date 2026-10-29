import 'dart:math';

import 'package:earnlens/core/date_time/local_date.dart';
import 'package:earnlens/domain/calculation/source_rules.dart';
import 'package:earnlens/domain/models/enums.dart';
import 'package:earnlens/domain/models/income_source.dart';
import 'package:earnlens/domain/money/fraction.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';

void main() {
  final engine = engineFor();
  final cal = engine.calendar;

  SourceRules salary(int monthly, {LocalDate? start, LocalDate? end, List<RateRevision>? revisions}) {
    final s = source(start: start, end: end);
    return SourceRules(source: s, revisions: revisions ?? [rev(s.id, s.startDate, monthly)]);
  }

  group('calendar-day monthly salary (₹35,000)', () {
    final r = salary(inr(35000));

    test('daily value depends on the actual month length', () {
      expect(engine.dayValue(r, d(2023, 2, 10)), Fraction.fromInt(inr(1250))); // 28 days
      expect(engine.dayValue(r, d(2024, 2, 10)), Fraction.fromInt(inr(35000), 29)); // leap
      expect(engine.dayValue(r, d(2024, 4, 10)), Fraction.fromInt(inr(35000), 30));
      expect(engine.dayValue(r, d(2024, 10, 10)), Fraction.fromInt(inr(35000), 31));
      expect(engine.dayValue(r, d(2024, 2, 10)).toDecimalString(4), '120689.6552');
    });

    test('a full month always totals exactly the monthly salary', () {
      for (final m in [YearMonth(2023, 2), YearMonth(2024, 2), YearMonth(2024, 4), YearMonth(2024, 12)]) {
        expect(engine.accruedForDates(r, DateRange.month(m)), Fraction.fromInt(inr(35000)), reason: '$m');
      }
    });

    test('half-way through a 30-day month accrues exactly half', () {
      final from = cal.dayStartMicros(d(2024, 4, 1));
      final mid = at(cal, 2024, 4, 16); // 15 full days elapsed
      expect(engine.accruedBetween(r, from, mid), Fraction.fromInt(inr(17500)));
    });

    test('accrual within a day is linear in time', () {
      final dayStart = at(cal, 2024, 4, 10);
      final noon = at(cal, 2024, 4, 10, 12);
      expect(engine.accruedBetween(r, dayStart, noon), Fraction.fromInt(inr(35000), 60));
    });

    test('never exceeds the monthly amount even with a later "now"', () {
      final range = DateRange.month(YearMonth(2024, 4));
      final farFuture = at(cal, 2030, 1, 1);
      expect(engine.accruedInRangeAsOf(r, range, farFuture), Fraction.fromInt(inr(35000)));
    });

    test('adjacent half-open ranges do not double count the boundary', () {
      final a = cal.dayStartMicros(d(2024, 1, 1));
      final b = at(cal, 2024, 1, 31, 23, 59);
      final c = cal.dayStartMicros(d(2024, 2, 1));
      final e = cal.dayStartMicros(d(2024, 3, 1));
      final split = engine.accruedBetween(r, a, b) + engine.accruedBetween(r, b, c) + engine.accruedBetween(r, c, e);
      expect(split, Fraction.fromInt(inr(70000)));
    });

    test('year boundary splits correctly', () {
      final dec31 = at(cal, 2024, 12, 31, 12);
      final jan1 = at(cal, 2025, 1, 1, 12);
      // 12h of Dec 31 + 12h of Jan 1, both 31-day months.
      expect(engine.accruedBetween(r, dec31, jan1), Fraction.fromInt(inr(35000), 31));
    });
  });

  group('employment period', () {
    test('joining mid-month accrues only from the joining date', () {
      final r = salary(inr(31000), start: d(2024, 10, 11)); // 21 of 31 days
      expect(engine.accruedForDates(r, DateRange.month(YearMonth(2024, 10))), Fraction.fromInt(inr(21000)));
    });

    test('leaving mid-month includes the last working day and stops after it', () {
      final r = salary(inr(30000), end: d(2024, 11, 10)); // 10 of 30 days
      expect(engine.accruedForDates(r, DateRange.month(YearMonth(2024, 11))), Fraction.fromInt(inr(10000)));
      expect(engine.dayValue(r, d(2024, 11, 11)), Fraction.zero);
      final late = engine.accruedBetween(r, cal.dayStartMicros(d(2024, 11, 11)), at(cal, 2025, 6, 1));
      expect(late, Fraction.zero);
    });

    test('nothing accrues before the start date', () {
      final r = salary(inr(30000), start: d(2024, 11, 1));
      expect(engine.accruedBetween(r, at(cal, 2024, 1, 1), at(cal, 2024, 11, 1)), Fraction.zero);
    });
  });

  group('salary revisions', () {
    final s = source();
    final revisions = [
      rev(s.id, d(2020, 1, 1), inr(30000)),
      rev(s.id, d(2024, 4, 16), inr(45000), type: RevisionChangeType.hike),
    ];
    final r = SourceRules(source: s, revisions: revisions);

    test('a hike only affects days from its effective date', () {
      expect(engine.accruedForDates(r, DateRange.month(YearMonth(2024, 3))), Fraction.fromInt(inr(30000)));
      // April: 15 days at 30k/30 + 15 days at 45k/30
      expect(engine.accruedForDates(r, DateRange.month(YearMonth(2024, 4))), Fraction.fromInt(inr(37500)));
      expect(engine.accruedForDates(r, DateRange.month(YearMonth(2024, 5))), Fraction.fromInt(inr(45000)));
    });

    test('later-created revision wins on the same effective date', () {
      final fixed = SourceRules(source: s, revisions: [
        rev(s.id, d(2024, 1, 1), inr(10000), createdAt: DateTime.utc(2024, 1, 1)),
        rev(s.id, d(2024, 1, 1), inr(20000), createdAt: DateTime.utc(2024, 2, 1)),
      ]);
      expect(engine.accruedForDates(fixed, DateRange.month(YearMonth(2024, 1))), Fraction.fromInt(inr(20000)));
    });
  });

  group('pauses and leave', () {
    test('a paused period earns nothing and resumes afterwards', () {
      final s = source();
      final r = SourceRules(
        source: s,
        revisions: [rev(s.id, s.startDate, inr(30000))],
        pauses: [SourcePause(id: 'p', sourceId: s.id, start: d(2024, 6, 11), endExclusive: d(2024, 6, 21))],
      );
      expect(engine.accruedForDates(r, DateRange.month(YearMonth(2024, 6))), Fraction.fromInt(inr(20000)));
    });

    test('unpaid leave on a calendar-day salary removes that day', () {
      final s = source();
      final r = SourceRules(
        source: s,
        revisions: [rev(s.id, s.startDate, inr(30000))],
        overrides: [DayOverride(id: 'o', date: d(2024, 6, 5), type: DayOverrideType.unpaidLeave)],
      );
      expect(engine.accruedForDates(r, DateRange.month(YearMonth(2024, 6))), Fraction.fromInt(inr(29000)));
    });
  });

  group('working-day policy', () {
    // October 2024: 23 weekdays (Mon–Fri).
    final s = source(policy: AccrualPolicy.workingDay);

    test('salary is spread across working days only', () {
      final r = SourceRules(source: s, revisions: [rev(s.id, s.startDate, inr(23000))]);
      expect(engine.dayValue(r, d(2024, 10, 1)), Fraction.fromInt(inr(1000))); // Tuesday
      expect(engine.dayValue(r, d(2024, 10, 5)), Fraction.zero); // Saturday
      expect(engine.accruedForDates(r, DateRange.month(YearMonth(2024, 10))), Fraction.fromInt(inr(23000)));
    });

    test('accrual happens only inside working hours', () {
      final r = SourceRules(source: s, revisions: [rev(s.id, s.startDate, inr(23000))]);
      expect(engine.accruedBetween(r, at(cal, 2024, 10, 1), at(cal, 2024, 10, 1, 9)), Fraction.zero);
      // 09:00–13:30 is half of a 9-hour window.
      expect(engine.accruedBetween(r, at(cal, 2024, 10, 1), at(cal, 2024, 10, 1, 13, 30)), Fraction.fromInt(inr(500)));
      expect(engine.accruedBetween(r, at(cal, 2024, 10, 1, 18), at(cal, 2024, 10, 2)), Fraction.zero);
    });

    test('paid holidays shrink the denominator; unpaid leave reduces pay', () {
      final r = SourceRules(source: s, revisions: [rev(s.id, s.startDate, inr(22000))], overrides: [
        DayOverride(id: 'h', date: d(2024, 10, 2), type: DayOverrideType.holiday),
        DayOverride(id: 'u', date: d(2024, 10, 3), type: DayOverrideType.unpaidLeave),
      ]);
      // 22 eligible working days → ₹1,000 each; one unpaid → ₹21,000.
      expect(engine.dayValue(r, d(2024, 10, 1)), Fraction.fromInt(inr(1000)));
      expect(engine.dayValue(r, d(2024, 10, 2)), Fraction.zero);
      expect(engine.accruedForDates(r, DateRange.month(YearMonth(2024, 10))), Fraction.fromInt(inr(21000)));
    });

    test('hourly rate pays rate × scheduled hours on working days', () {
      final hourly = source(policy: AccrualPolicy.workingDay);
      final r = SourceRules(source: hourly, revisions: [rev(hourly.id, hourly.startDate, inr(500), period: RatePeriod.hour)]);
      expect(engine.dayValue(r, d(2024, 10, 1)), Fraction.fromInt(inr(4500)));
      expect(engine.accruedForDates(r, DateRange.month(YearMonth(2024, 10))), Fraction.fromInt(inr(4500 * 23)));
    });
  });

  group('temporary work', () {
    test('day-rate job stops accruing after its end date', () {
      final s = source(kind: IncomeKind.temporary, start: d(2024, 10, 10), end: d(2024, 10, 24));
      final r = SourceRules(source: s, revisions: [rev(s.id, s.startDate, inr(2000), period: RatePeriod.day)]);
      expect(engine.accruedForDates(r, DateRange.month(YearMonth(2024, 10))), Fraction.fromInt(inr(30000)));
      final after = engine.accruedBetween(r, cal.dayStartMicros(d(2024, 10, 25)), at(cal, 2025, 1, 1));
      expect(after, Fraction.zero);
    });

    test('fixed total spread over calendar days', () {
      final s = source(kind: IncomeKind.temporary, start: d(2024, 10, 10), end: d(2024, 10, 24), fixedTotal: inr(15000));
      final r = SourceRules(source: s, revisions: const []);
      expect(engine.dayValue(r, d(2024, 10, 12)), Fraction.fromInt(inr(1000)));
      expect(engine.accruedForDates(r, DateRange.month(YearMonth(2024, 10))), Fraction.fromInt(inr(15000)));
    });

    test('fixed total earned on completion lands in the end month only', () {
      final s = source(
        kind: IncomeKind.temporary,
        start: d(2024, 10, 20),
        end: d(2024, 10, 31),
        fixedTotal: inr(50000),
        fixedTotalAccrual: FixedTotalAccrual.onCompletion,
      );
      final r = SourceRules(source: s, revisions: const []);
      expect(engine.accruedInRangeAsOf(r, DateRange.month(YearMonth(2024, 10)), at(cal, 2024, 10, 31, 23)), Fraction.zero);
      expect(engine.accruedInRangeAsOf(r, DateRange.month(YearMonth(2024, 10)), at(cal, 2024, 11, 2)), Fraction.fromInt(inr(50000)));
      expect(engine.accruedInRangeAsOf(r, DateRange.month(YearMonth(2024, 11)), at(cal, 2024, 12, 2)), Fraction.zero);
    });
  });

  group('timezones and DST', () {
    test('a 23-hour DST day still accrues exactly one day value', () {
      final ny = engineFor('America/New_York');
      final s = source();
      final r = SourceRules(source: s, revisions: [rev(s.id, s.startDate, inr(31000))]);
      final from = ny.calendar.dayStartMicros(d(2024, 3, 10)); // spring forward
      final to = ny.calendar.dayStartMicros(d(2024, 3, 11));
      expect(to - from, 23 * 3600 * 1000000);
      expect(ny.accruedBetween(r, from, to), Fraction.fromInt(inr(1000)));
    });

    test('the same instant is interpreted by the financial timezone, not the device', () {
      final kolkata = engineFor('Asia/Kolkata');
      final la = engineFor('America/Los_Angeles');
      final s = source();
      final r = SourceRules(source: s, revisions: [rev(s.id, s.startDate, inr(31000))]);
      final range = DateRange.month(YearMonth(2024, 10));
      // Historical full-month figures are timezone-independent.
      expect(kolkata.accruedForDates(r, range), la.accruedForDates(r, range));
    });
  });

  group('regression', () {
    test('live counter recomputed after a long gap equals continuous ticking', () {
      final r = salary(inr(35000));
      final start = at(cal, 2024, 10, 1);
      final end = at(cal, 2024, 10, 19, 15, 37);
      var ticked = Fraction.zero;
      var t = start;
      final rng = Random(42);
      while (t < end) {
        final next = min(end, t + (rng.nextInt(36) + 1) * 3600 * 1000000);
        ticked += engine.accruedBetween(r, t, next);
        t = next;
      }
      expect(ticked, engine.accruedBetween(r, start, end));
    });

    test('rounding displayed per-second values does not leak into totals', () {
      final r = salary(inr(35000));
      final perSecond = engine.dayValue(r, d(2024, 10, 1)).divInt(86400);
      final roundedPerSecond = Fraction(perSecond.roundHalfEven());
      final authoritative = engine.accruedForDates(r, DateRange.month(YearMonth(2024, 10)));
      final naive = roundedPerSecond.timesInt(31 * 86400);
      expect(authoritative, Fraction.fromInt(inr(35000)));
      expect(naive == authoritative, isFalse);
    });

    test('randomised: sum of daily ranges equals the month for any salary', () {
      final rng = Random(7);
      for (var i = 0; i < 50; i++) {
        final amount = rng.nextInt(10000000) + 1;
        final year = 1990 + rng.nextInt(60);
        final month = rng.nextInt(12) + 1;
        final r = salary(amount, start: d(1980, 1, 1));
        final m = YearMonth(year, month);
        var sum = Fraction.zero;
        for (final day in DateRange.month(m).days) {
          sum += engine.accruedBetween(r, cal.dayStartMicros(day), cal.dayStartMicros(day.addDays(1)));
        }
        expect(sum, Fraction.fromInt(amount), reason: '$amount in $m');
      }
    });
  });
}
