import '../../core/date_time/local_date.dart';
import '../models/enums.dart';
import '../models/income_source.dart';
import '../money/fraction.dart';
import 'earnings_calculator.dart';
import 'earnings_snapshot.dart';

/// A forecast is always an estimate. [known] is the part already earned or
/// recorded; [projected] is the estimated remainder.
class Forecast {
  const Forecast({required this.known, required this.projected, required this.bySource});

  final int known;
  final int projected;
  final Map<String, int> bySource;

  int get total => known + projected;
}

/// Forecasting rules (see docs/CALCULATION_RULES.md §8):
/// * rule-based income: full accrual from the configured rates
/// * variable income: recorded actual, else the configured method
///   (estimate / average of last 3 or 6 months with actuals), never less
///   than what is already recorded
/// * compensation items: recorded actuals, planned items marked for
///   forecasting, and future occurrences of recurring items
class ForecastCalculator {
  const ForecastCalculator(this.calculator);

  final EarningsCalculator calculator;

  Forecast forMonth(
    EarningsSnapshot snap,
    YearMonth month,
    int nowMicros, {
    required String currencyCode,
    Set<String>? sourceIds,
  }) {
    final today = calculator.engine.calendar.dateOf(nowMicros);
    final range = DateRange.month(month);
    var known = 0;
    var projected = 0;
    final bySource = <String, int>{};

    for (final s in snap.sources) {
      if (s.currencyCode != currencyCode) continue;
      if (sourceIds != null && !sourceIds.contains(s.id)) continue;
      final summary = calculator.summarizeSource(snap, s, range, nowMicros, today);
      final sourceKnown = summary.actual;
      final itemsKnown = _earnedItems(snap, s, range, today);

      var base = 0;
      if (s.kind.accruesContinuously) {
        base = calculator.engine.accruedForDates(snap.rules[s.id]!, range).roundToInt();
      } else if (s.kind == IncomeKind.variable) {
        final variableKnown = sourceKnown - itemsKnown - summary.adjustments;
        final rec = snap.record(s.id, month);
        base = rec?.actualMinor ?? _max(variableKnown, _variableProjection(snap, s, month) ?? variableKnown);
      }

      final sourceTotal = base +
          summary.adjustments +
          itemsKnown +
          _plannedItems(snap, s, range, today) +
          _recurringProjections(snap, s, month);

      known += sourceKnown;
      projected += sourceTotal - sourceKnown;
      bySource[s.id] = sourceTotal;
    }
    return Forecast(known: known, projected: projected < 0 ? 0 : projected, bySource: bySource);
  }

  /// Year forecast: completed months use recorded figures; the current and
  /// future months use [forMonth].
  Forecast forYear(
    EarningsSnapshot snap,
    int year,
    int nowMicros, {
    required String currencyCode,
    Set<String>? sourceIds,
  }) {
    final current = calculator.engine.calendar.dateOf(nowMicros).yearMonth;
    var known = 0;
    var projected = 0;
    final bySource = <String, int>{};
    for (var m = 1; m <= 12; m++) {
      final ym = YearMonth(year, m);
      if (ym.isBefore(current)) {
        final s = calculator.summarize(snap, DateRange.month(ym), nowMicros,
            currencyCode: currencyCode, sourceIds: sourceIds);
        known += s.actual;
        for (final src in s.sources) {
          bySource[src.source.id] = (bySource[src.source.id] ?? 0) + src.actual;
        }
      } else {
        final f = forMonth(snap, ym, nowMicros, currencyCode: currencyCode, sourceIds: sourceIds);
        known += f.known;
        projected += f.projected;
        f.bySource.forEach((k, v) => bySource[k] = (bySource[k] ?? 0) + v);
      }
    }
    return Forecast(known: known, projected: projected, bySource: bySource);
  }

  int? _variableProjection(EarningsSnapshot snap, IncomeSource s, YearMonth month) {
    if (month.isBefore(s.startDate.yearMonth)) return null;
    if (s.endDate != null && month.isAfter(s.endDate!.yearMonth)) return null;
    switch (s.forecastMethod) {
      case ForecastMethod.estimate:
        return snap.variableExpected(s.id, month);
      case ForecastMethod.average3:
      case ForecastMethod.average6:
        final n = s.forecastMethod == ForecastMethod.average3 ? 3 : 6;
        final values = <int>[];
        for (var i = 1; i <= 24 && values.length < n; i++) {
          final v = snap.variableActual(s.id, month.addMonths(-i));
          if (v != null) values.add(v);
        }
        if (values.isEmpty) return snap.variableExpected(s.id, month);
        return (Fraction.fromInt(values.fold(0, (a, b) => a + b), values.length)).roundToInt();
    }
  }

  int _earnedItems(EarningsSnapshot snap, IncomeSource s, DateRange range, LocalDate today) {
    var sum = 0;
    for (final i in snap.itemsFor(s.id)) {
      if (i.countsAsEarnings && i.isEarned && range.contains(i.earnedDate!) && !i.earnedDate!.isAfter(today)) {
        sum += i.actualMinor!;
      }
    }
    return sum;
  }

  /// Items planned in [range] that are not yet earned.
  int _plannedItems(EarningsSnapshot snap, IncomeSource s, DateRange range, LocalDate today) {
    var sum = 0;
    for (final i in snap.itemsFor(s.id)) {
      if (!i.countsAsEarnings || !i.includeInForecast) continue;
      if (i.isEarned && !i.earnedDate!.isAfter(today)) continue;
      final d = i.planningDate;
      if (d != null && range.contains(d)) sum += i.actualMinor ?? i.expectedMinor ?? 0;
    }
    return sum;
  }

  /// Future occurrences of recurring items falling in [month] (only after
  /// the original occurrence, and never for one-time items).
  int _recurringProjections(EarningsSnapshot snap, IncomeSource s, YearMonth month) {
    var sum = 0;
    for (final i in snap.itemsFor(s.id)) {
      if (i.recurrence == Recurrence.none || !i.includeInForecast || !i.countsAsEarnings) continue;
      final d = i.planningDate;
      if (d == null) continue;
      final diff = d.yearMonth.monthsUntil(month);
      if (diff <= 0 || diff % i.recurrence.months != 0) continue;
      if (s.endDate != null && month.isAfter(s.endDate!.yearMonth)) continue;
      // Skip if a concrete item of the same type already exists that month.
      final exists = snap.itemsFor(s.id).any((o) =>
          o.id != i.id && o.type == i.type && o.planningDate?.yearMonth == month);
      if (exists) continue;
      sum += i.expectedMinor ?? i.actualMinor ?? 0;
    }
    return sum;
  }

  static int _max(int a, int b) => a > b ? a : b;
}
