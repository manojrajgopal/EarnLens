import '../../core/date_time/local_date.dart';
import '../money/fraction.dart';
import 'accrual_engine.dart';
import 'source_rules.dart';

enum EarningUnit {
  second,
  minute,
  hour,
  day,
  week,
  month,
  quarter,
  year;

  String get label => switch (this) {
        second => 'Per second',
        minute => 'Per minute',
        hour => 'Per hour',
        day => 'Per day',
        week => 'Per week',
        month => 'Per month',
        quarter => 'Per quarter',
        year => 'Per year',
      };

  String get shortLabel => switch (this) {
        second => '/sec',
        minute => '/min',
        hour => '/hr',
        day => '/day',
        week => '/wk',
        month => '/mo',
        quarter => '/qtr',
        year => '/yr',
      };

  /// Sub-day units have a basis choice (calendar time vs working time).
  bool get isSubDay => this == second || this == minute || this == hour;
}

/// How sub-day rates are expressed.
enum RateBasis {
  /// Divide a 7-day week by 168 hours (matches the calendar-day live counter).
  calendarTime,

  /// Divide a 7-day week by the scheduled working hours in that week.
  workingTime;

  String get label => switch (this) {
        calendarTime => 'Around the clock (24h days)',
        workingTime => 'Working hours only',
      };
}

/// Converts each source's current rate into every [EarningUnit].
///
/// Definitions (all at the rate in force on the reference date):
/// * month   = sum of nominal day values across the reference calendar month
/// * quarter = sum across the three months of the reference quarter
/// * year    = sum across the twelve months of the reference year
/// * day     = month / days in that month (calendar policy) or the value of a
///             working day (working-day policy)
/// * week    = nominal value of the 7 days starting on the reference date
/// * hour, calendar basis = day / 24 for calendar-time sources, week / 168
///   for working-time sources
/// * hour, working basis  = day / scheduled hours for working-time sources,
///   week / scheduled weekly hours for calendar-time sources
/// * minute  = hour / 60, second = minute / 60
class RateCalculator {
  const RateCalculator(this.engine);

  final AccrualEngine engine;

  Fraction rate(SourceRules r, EarningUnit unit, LocalDate ref, {RateBasis basis = RateBasis.calendarTime}) {
    if (!r.source.kind.accruesContinuously) return Fraction.zero;
    if (!r.inEmploymentRange(ref) || r.isPaused(ref)) return Fraction.zero;
    switch (unit) {
      case EarningUnit.month:
        return _sumMonths(r, ref.yearMonth, 1, ref);
      case EarningUnit.quarter:
        final qStart = YearMonth(ref.year, ((ref.month - 1) ~/ 3) * 3 + 1);
        return _sumMonths(r, qStart, 3, ref);
      case EarningUnit.year:
        return _sumMonths(r, YearMonth(ref.year, 1), 12, ref);
      case EarningUnit.day:
        return _typicalDay(r, ref);
      case EarningUnit.week:
        return _week(r, ref);
      case EarningUnit.hour:
      case EarningUnit.minute:
      case EarningUnit.second:
        final working = engine.usesWorkingTimeOn(r, ref);
        final Fraction perMinute;
        if (basis == RateBasis.calendarTime) {
          // Calendar sources: today's day value over 24h, matching the live counter.
          perMinute = working ? _week(r, ref).divInt(7 * 24 * 60) : _typicalDay(r, ref).divInt(24 * 60);
        } else {
          final dayMinutes = r.schedule.workingMinutesPerDay;
          final weekMinutes = r.schedule.weekdays.length * dayMinutes;
          if (dayMinutes <= 0 || weekMinutes <= 0) return Fraction.zero;
          // Working sources: a working day's value over its scheduled hours.
          perMinute = working ? _typicalDay(r, ref).divInt(dayMinutes) : _week(r, ref).divInt(weekMinutes);
        }
        return switch (unit) {
          EarningUnit.hour => perMinute.timesInt(60),
          EarningUnit.minute => perMinute,
          _ => perMinute.divInt(60),
        };
    }
  }

  Fraction _sumMonths(SourceRules r, YearMonth first, int count, LocalDate ref) {
    var total = Fraction.zero;
    for (var i = 0; i < count; i++) {
      for (final d in DateRange.month(first.addMonths(i)).days) {
        total += engine.nominalDayValueAt(r, d, ref) ?? Fraction.zero;
      }
    }
    return total;
  }

  Fraction _typicalDay(SourceRules r, LocalDate ref) {
    if (!engine.usesWorkingTimeOn(r, ref)) return engine.nominalDayValueAt(r, ref, ref) ?? Fraction.zero;
    // Value of a working day in the reference month.
    for (final d in DateRange.month(ref.yearMonth).days) {
      if (r.isWorkingDay(d)) return engine.nominalDayValueAt(r, d, ref) ?? Fraction.zero;
    }
    return Fraction.zero;
  }

  Fraction _week(SourceRules r, LocalDate ref) {
    var total = Fraction.zero;
    for (var i = 0; i < 7; i++) {
      total += engine.nominalDayValueAt(r, ref.addDays(i), ref) ?? Fraction.zero;
    }
    return total;
  }
}
