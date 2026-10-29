import '../../core/date_time/local_date.dart';
import '../models/enums.dart';
import '../money/fraction.dart';
import 'financial_calendar.dart';
import 'source_rules.dart';

/// Computes how much a rule-based income source has earned between two
/// instants. See docs/CALCULATION_RULES.md for the full specification.
///
/// Model: every eligible local day has a *day value*. That value accrues
/// linearly across the day's *accrual window* — the whole day for calendar
/// policies, or the configured working hours for working-time policies.
/// All intervals are half-open `[start, end)`.
class AccrualEngine {
  const AccrualEngine(this.calendar);

  final FinancialCalendar calendar;

  /// Value earned on day [d] in minor units (exact).
  Fraction dayValue(SourceRules r, LocalDate d) {
    final s = r.source;
    if (!s.kind.accruesContinuously) return Fraction.zero;
    if (!r.inEmploymentRange(d) || r.isPaused(d)) return Fraction.zero;

    if (s.usesFixedTotal) return _fixedTotalDayValue(r, d);

    final rev = r.revisionOn(d);
    if (rev == null || rev.amountMinor == 0) return Fraction.zero;
    final working = _usesWorkingTime(r, rev.period);
    if (working && (!r.isWorkingDay(d) || r.isUnpaidLeave(d))) return Fraction.zero;
    if (!working && r.isUnpaidLeave(d)) return Fraction.zero;
    return _nominalDayValue(r, d, rev.amountMinor, rev.period);
  }

  /// Day value for an eligible day at the given rate, ignoring eligibility,
  /// pauses and unpaid leave (but respecting working days/holidays for the
  /// denominator). Used for nominal rate displays.
  Fraction _nominalDayValue(SourceRules r, LocalDate d, int amountMinor, RatePeriod period) {
    final amount = Fraction.fromInt(amountMinor);
    final working = _usesWorkingTime(r, period);
    switch (period) {
      case RatePeriod.hour:
        return amount.timesInt(r.schedule.workingMinutesPerDay).divInt(60);
      case RatePeriod.day:
        return amount;
      case RatePeriod.week:
        return working ? amount.divInt(r.schedule.weekdays.length) : amount.divInt(7);
      case RatePeriod.month:
      case RatePeriod.year:
        final monthly = period == RatePeriod.year ? amount.divInt(12) : amount;
        if (working) {
          final days = r.workingDaysInMonth(d.yearMonth);
          return days == 0 ? Fraction.zero : monthly.divInt(days);
        }
        return monthly.divInt(LocalDate.daysInMonth(d.year, d.month));
    }
  }

  Fraction _fixedTotalDayValue(SourceRules r, LocalDate d) {
    final s = r.source;
    final total = Fraction.fromInt(s.fixedTotalMinor!);
    switch (s.fixedTotalAccrual) {
      case FixedTotalAccrual.onCompletion:
        return d == s.endDate ? total : Fraction.zero;
      case FixedTotalAccrual.spreadWorkingDays:
        if (!r.isWorkingDay(d) || r.isUnpaidLeave(d)) return Fraction.zero;
        final n = r.fixedTotalDays();
        return n == 0 ? Fraction.zero : total.divInt(n);
      case FixedTotalAccrual.spreadCalendarDays:
        if (r.isUnpaidLeave(d)) return Fraction.zero;
        final n = r.fixedTotalDays();
        return n == 0 ? Fraction.zero : total.divInt(n);
    }
  }

  bool _usesWorkingTime(SourceRules r, RatePeriod period) =>
      period == RatePeriod.hour || r.usesWorkingTime;

  /// Whether the rate in force on [d] accrues only during working hours.
  bool usesWorkingTimeOn(SourceRules r, LocalDate d) {
    if (r.source.usesFixedTotal) return r.usesWorkingTime;
    final rev = r.revisionOn(d);
    return rev == null ? r.usesWorkingTime : _usesWorkingTime(r, rev.period);
  }

  /// The `[start, end)` instants across which day [d]'s value accrues.
  (int, int) accrualWindow(SourceRules r, LocalDate d) {
    final rev = r.source.usesFixedTotal ? null : r.revisionOn(d);
    final working = rev == null ? r.usesWorkingTime : _usesWorkingTime(r, rev.period);
    if (working) {
      return (
        calendar.localTimeMicros(d, r.schedule.startMinute),
        calendar.localTimeMicros(d, r.schedule.endMinute),
      );
    }
    return (calendar.dayStartMicros(d), calendar.dayStartMicros(d.addDays(1)));
  }

  /// Earnings accrued in the instant interval `[fromMicros, toMicros)`.
  Fraction accruedBetween(SourceRules r, int fromMicros, int toMicros) {
    if (toMicros <= fromMicros || !r.source.kind.accruesContinuously) return Fraction.zero;
    final s = r.source;
    var firstDay = calendar.dateOf(fromMicros).max(s.startDate);
    var lastDay = calendar.dateOf(toMicros - 1);
    if (s.endDate != null) lastDay = lastDay.min(s.endDate!);
    if (lastDay.isBefore(firstDay)) return Fraction.zero;

    if (s.usesFixedTotal && s.fixedTotalAccrual == FixedTotalAccrual.onCompletion) {
      final end = s.endDate!;
      final v = dayValue(r, end);
      if (v.isZero) return Fraction.zero;
      // Recognised at the instant the last day's window closes: included when
      // from < t <= to so the amount lands in the period containing that day.
      final t = accrualWindow(r, end).$2;
      return fromMicros < t && t <= toMicros ? v : Fraction.zero;
    }

    var total = Fraction.zero;
    for (var d = firstDay; !d.isAfter(lastDay); d = d.addDays(1)) {
      final v = dayValue(r, d);
      if (v.isZero) continue;
      final (ws, we) = accrualWindow(r, d);
      final overlapStart = fromMicros > ws ? fromMicros : ws;
      final overlapEnd = toMicros < we ? toMicros : we;
      if (overlapEnd <= overlapStart) continue;
      final length = we - ws;
      if (overlapStart == ws && overlapEnd == we) {
        total += v;
      } else {
        total += v * Fraction(BigInt.from(overlapEnd - overlapStart), BigInt.from(length));
      }
    }
    return total;
  }

  /// Earnings for whole days in [range] (independent of the current time).
  Fraction accruedForDates(SourceRules r, DateRange range) {
    if (!r.source.kind.accruesContinuously) return Fraction.zero;
    var total = Fraction.zero;
    final s = r.source;
    var start = range.start.max(s.startDate);
    var end = range.endExclusive;
    if (s.endExclusive != null) end = end.min(s.endExclusive!);
    for (var d = start; d.isBefore(end); d = d.addDays(1)) {
      total += dayValue(r, d);
    }
    return total;
  }

  /// Earnings in [range] up to [nowMicros] (whole range if it is in the past).
  Fraction accruedInRangeAsOf(SourceRules r, DateRange range, int nowMicros) {
    final from = calendar.dayStartMicros(range.start);
    final to = calendar.dayStartMicros(range.endExclusive);
    if (nowMicros >= to) return accruedForDates(r, range);
    return accruedBetween(r, from, nowMicros < to ? nowMicros : to);
  }

  /// Nominal earnings for one day at the source's current rate as of [ref].
  /// Returns null when the source has no applicable rate.
  Fraction? nominalDayValueAt(SourceRules r, LocalDate d, LocalDate ref) {
    final s = r.source;
    if (s.usesFixedTotal) {
      final n = r.fixedTotalDays();
      if (n == 0) return null;
      final total = Fraction.fromInt(s.fixedTotalMinor!);
      if (r.usesWorkingTime && !r.isWorkingDay(d)) return Fraction.zero;
      return total.divInt(n);
    }
    final rev = r.revisionOn(ref);
    if (rev == null) return null;
    if (_usesWorkingTime(r, rev.period) && !r.isWorkingDay(d)) return Fraction.zero;
    return _nominalDayValue(r, d, rev.amountMinor, rev.period);
  }
}
