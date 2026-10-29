import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/date_time/local_date.dart';
import '../../../core/formatting/money_format.dart';
import '../../../domain/calculation/earnings_calculator.dart';
import '../../../domain/calculation/forecast_calculator.dart';
import '../../../domain/calculation/payment_schedule.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/income_source.dart';
import '../../../domain/models/records.dart';

/// Time windows offered by the Insights range filter.
enum InsightsRange {
  sixMonths,
  twelveMonths,
  thisYear,
  lastYear;

  String get label => switch (this) {
        sixMonths => '6M',
        twelveMonths => '12M',
        thisYear => 'This year',
        lastYear => 'Last year',
      };

  String get description => switch (this) {
        sixMonths => 'the last 6 months',
        twelveMonths => 'the last 12 months',
        thisYear => 'this year so far',
        lastYear => 'last year',
      };

  /// Last month of the window and the number of months, oldest first.
  (YearMonth last, int count) window(YearMonth current) => switch (this) {
        sixMonths => (current, 6),
        twelveMonths => (current, 12),
        thisYear => (current, current.month),
        lastYear => (YearMonth(current.year - 1, 12), 12),
      };
}

typedef InsightsQuery = ({InsightsRange range, String? sourceId});

class SourceShare {
  const SourceShare(this.source, this.amount, this.shareBps);
  final IncomeSource source;
  final int amount;

  /// Share of the total in basis points (10000 = 100%).
  final int shareBps;
}

class CategoryShare {
  const CategoryShare(this.label, this.amount, this.shareBps);
  final String label;
  final int amount;
  final int shareBps;
}

class MonthValue {
  const MonthValue(this.month, this.amount);
  final YearMonth month;
  final int amount;
}

class RevisionRow {
  const RevisionRow({required this.source, required this.revision, this.changeFromPrevious});
  final IncomeSource source;
  final RateRevision revision;

  /// Formatted change vs the previous revision with the same period, e.g. "+12.0%".
  final String? changeFromPrevious;
}

class BonusRow {
  const BonusRow(this.item, this.sourceName);
  final CompensationItem item;
  final String? sourceName;
}

/// Comparison of a reference month with an earlier month.
class MonthComparison {
  const MonthComparison(this.month, this.amount, this.otherMonth, this.otherAmount);
  final YearMonth month;
  final int amount;
  final YearMonth otherMonth;
  final int otherAmount;

  /// Null when the earlier month had no earnings (no meaningful percentage).
  String? get percent => percentChange(otherAmount, amount);
  int get delta => amount - otherAmount;
}

class InsightsData {
  const InsightsData({
    required this.hasSources,
    required this.filterSources,
    required this.current,
    required this.series,
    required this.totalExpected,
    required this.totalActual,
    required this.distribution,
    required this.categories,
    required this.monthOverMonth,
    required this.yearOverYear,
    required this.best,
    required this.lowest,
    required this.salaryHistory,
    required this.bonuses,
    required this.outstandingTotal,
    required this.outstandingCount,
    required this.monthForecast,
    required this.yearForecast,
  });

  final bool hasSources;

  /// Sources in the profile currency (offered by the source filter).
  final List<IncomeSource> filterSources;
  final YearMonth current;
  final List<PeriodSummary> series;
  final int totalExpected;
  final int totalActual;
  final List<SourceShare> distribution;
  final List<CategoryShare> categories;
  final MonthComparison? monthOverMonth;
  final MonthComparison? yearOverYear;
  final MonthValue? best;
  final MonthValue? lowest;
  final List<RevisionRow> salaryHistory;
  final List<BonusRow> bonuses;
  final int outstandingTotal;
  final int outstandingCount;
  final Forecast monthForecast;
  final Forecast yearForecast;

  int get totalVariance => totalActual - totalExpected;
}

const bonusTypes = {
  CompensationType.joiningBonus,
  CompensationType.annualBonus,
  CompensationType.performanceIncentive,
  CompensationType.recurringBonus,
  CompensationType.oneTimeIncome,
  CompensationType.other,
};

int _bps(int part, int total) => total <= 0 ? 0 : part * 10000 ~/ total;

/// All Insights figures, computed once per (range, source) and snapshot change.
final insightsProvider = Provider.autoDispose.family<InsightsData, InsightsQuery>((ref, q) {
  final snap = ref.watch(snapshotProvider);
  final calc = ref.watch(earningsCalculatorProvider);
  final forecasts = ref.watch(forecastCalculatorProvider);
  final currency = ref.watch(currencyProvider).code;
  final today = ref.watch(todayProvider);
  final nowMicros = ref.watch(clockProvider).now().microsecondsSinceEpoch;
  final payments = ref.watch(expectedPaymentsProvider);

  final filterSources = snap.sources.where((s) => s.currencyCode == currency).toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  final validId = q.sourceId != null && filterSources.any((s) => s.id == q.sourceId);
  final ids = validId ? {q.sourceId!} : null;
  final current = today.yearMonth;

  final (last, count) = q.range.window(current);
  final series = calc.monthlySeries(snap, last, count, nowMicros, currencyCode: currency, sourceIds: ids);

  PeriodSummary month(YearMonth m) =>
      calc.summarize(snap, DateRange.month(m), nowMicros, currencyCode: currency, sourceIds: ids);

  var totalExpected = 0;
  var totalActual = 0;
  final bySource = <String, int>{};
  for (final p in series) {
    totalExpected += p.expected;
    totalActual += p.actual;
    for (final s in p.sources) {
      bySource[s.source.id] = (bySource[s.source.id] ?? 0) + s.actual;
    }
  }

  // Distribution only over positive contributions so percentages add up.
  final positiveTotal = bySource.values.where((v) => v > 0).fold(0, (a, b) => a + b);
  final distribution = [
    for (final s in filterSources)
      if ((bySource[s.id] ?? 0) > 0) SourceShare(s, bySource[s.id]!, _bps(bySource[s.id]!, positiveTotal)),
  ]..sort((a, b) => b.amount.compareTo(a.amount));

  final byCategory = <String, int>{};
  for (final d in distribution) {
    byCategory[d.source.categoryLabel] = (byCategory[d.source.categoryLabel] ?? 0) + d.amount;
  }
  final categories = [
    for (final e in byCategory.entries) CategoryShare(e.key, e.value, _bps(e.value, positiveTotal)),
  ]..sort((a, b) => b.amount.compareTo(a.amount));

  // Reference month: the latest completed month in the window (the current
  // month is still in progress and would distort comparisons).
  final ref0 = last.isBefore(current) ? last : current.previous;
  final byMonth = {for (final p in series) p.range.start.yearMonth: p};
  PeriodSummary cached(YearMonth m) => byMonth[m] ?? month(m);
  final refSummary = cached(ref0);
  final prev = cached(ref0.previous);
  final yoy = month(ref0.addMonths(-12));
  final mom = MonthComparison(ref0, refSummary.actual, ref0.previous, prev.actual);
  final yearOver = MonthComparison(ref0, refSummary.actual, ref0.addMonths(-12), yoy.actual);

  MonthValue? best;
  MonthValue? lowest;
  for (final p in series) {
    final m = p.range.start.yearMonth;
    if (!m.isBefore(current)) continue; // completed months only
    if (p.expected == 0 && p.actual == 0) continue;
    if (best == null || p.actual > best.amount) best = MonthValue(m, p.actual);
    if (lowest == null || p.actual < lowest.amount) lowest = MonthValue(m, p.actual);
  }

  final salaryHistory = <RevisionRow>[];
  for (final s in filterSources) {
    if (s.kind != IncomeKind.salary || (ids != null && !ids.contains(s.id))) continue;
    final revs = snap.rules[s.id]?.revisions ?? const <RateRevision>[];
    RateRevision? previous;
    for (final r in revs) {
      final change = previous != null && previous.period == r.period
          ? percentChange(previous.amountMinor, r.amountMinor)
          : null;
      salaryHistory.add(RevisionRow(source: s, revision: r, changeFromPrevious: change));
      previous = r;
    }
  }
  salaryHistory.sort((a, b) => b.revision.effectiveFrom.compareTo(a.revision.effectiveFrom));

  final names = {for (final s in snap.sources) s.id: s.name};
  final bonuses = [
    for (final i in snap.items)
      if (!i.cancelled &&
          i.currencyCode == currency &&
          bonusTypes.contains(i.type) &&
          (ids == null || ids.contains(i.sourceId)))
        BonusRow(i, names[i.sourceId]),
  ]..sort((a, b) {
      final da = a.item.planningDate ?? LocalDate(1970, 1, 1);
      final db = b.item.planningDate ?? LocalDate(1970, 1, 1);
      return db.compareTo(da);
    });

  var outstandingTotal = 0;
  var outstandingCount = 0;
  for (final p in payments) {
    if (p.status != PaymentStatus.overdue && p.status != PaymentStatus.partiallyReceived) continue;
    if (ids != null && !ids.contains(p.sourceId)) continue;
    outstandingTotal += p.outstandingMinor;
    outstandingCount++;
  }

  return InsightsData(
    hasSources: snap.sources.isNotEmpty,
    filterSources: filterSources,
    current: current,
    series: series,
    totalExpected: totalExpected,
    totalActual: totalActual,
    distribution: distribution,
    categories: categories,
    monthOverMonth: mom,
    yearOverYear: yearOver,
    best: best,
    lowest: lowest,
    salaryHistory: salaryHistory,
    bonuses: bonuses,
    outstandingTotal: outstandingTotal,
    outstandingCount: outstandingCount,
    monthForecast: forecasts.forMonth(snap, current, nowMicros, currencyCode: currency, sourceIds: ids),
    yearForecast: forecasts.forYear(snap, current.year, nowMicros, currencyCode: currency, sourceIds: ids),
  );
});
