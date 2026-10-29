import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/date_time/local_date.dart';
import '../../../core/formatting/money_format.dart';
import '../../../domain/calculation/earnings_calculator.dart';
import '../../../domain/models/income_source.dart';

class MonthHistoryData {
  const MonthHistoryData({
    required this.month,
    required this.current,
    required this.summary,
    required this.previous,
    required this.itemsEarned,
    required this.adjustments,
    required this.ytd,
    required this.rows,
    required this.sources,
  });

  final YearMonth month;
  final YearMonth current;
  final PeriodSummary summary;
  final PeriodSummary previous;

  /// Bonuses and one-time items earned in the month.
  final int itemsEarned;

  /// Signed earnings adjustments recorded for the month.
  final int adjustments;

  /// 1 January up to the end of [month].
  final PeriodSummary ytd;

  /// Per-source rows worth showing (eligible during the month or with activity).
  final List<SourceSummary> rows;

  /// All sources in the profile currency (for "record" pickers).
  final List<IncomeSource> sources;

  bool get isFuture => month.isAfter(current);
  bool get isCurrent => month == current;
  String? get momPercent => percentChange(previous.actual, summary.actual);
  int get momDelta => summary.actual - previous.actual;
}

bool _eligible(IncomeSource s, DateRange r) =>
    s.startDate.isBefore(r.endExclusive) && (s.endDate == null || !s.endDate!.isBefore(r.start));

final monthHistoryProvider = Provider.autoDispose.family<MonthHistoryData, YearMonth>((ref, month) {
  final snap = ref.watch(snapshotProvider);
  final calc = ref.watch(earningsCalculatorProvider);
  final currency = ref.watch(currencyProvider).code;
  final today = ref.watch(todayProvider);
  final nowMicros = ref.watch(clockProvider).now().microsecondsSinceEpoch;

  final range = DateRange.month(month);
  final summary = calc.summarize(snap, range, nowMicros, currencyCode: currency);
  final previous = calc.summarize(snap, DateRange.month(month.previous), nowMicros, currencyCode: currency);
  final ytd = calc.summarize(snap, DateRange(LocalDate(month.year, 1, 1), month.endExclusive), nowMicros,
      currencyCode: currency);

  var itemsEarned = 0;
  for (final i in snap.items) {
    if (i.currencyCode != currency || !i.countsAsEarnings || !i.isEarned) continue;
    if (range.contains(i.earnedDate!) && !i.earnedDate!.isAfter(today)) itemsEarned += i.actualMinor!;
  }
  final adjustments = summary.sources.fold(0, (a, s) => a + s.adjustments);

  final rows = [
    for (final s in summary.sources)
      if (_eligible(s.source, range) || s.actual != 0 || s.received != 0 || s.expected != 0) s,
  ]..sort((a, b) => a.source.sortOrder.compareTo(b.source.sortOrder));

  return MonthHistoryData(
    month: month,
    current: today.yearMonth,
    summary: summary,
    previous: previous,
    itemsEarned: itemsEarned,
    adjustments: adjustments,
    ytd: ytd,
    rows: rows,
    sources: snap.sources.where((s) => s.currencyCode == currency).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
  );
});

/// Summary for a user-chosen custom range (partial months handled by the calculator).
final customRangeSummaryProvider = Provider.autoDispose.family<PeriodSummary, DateRange>((ref, range) {
  final snap = ref.watch(snapshotProvider);
  final calc = ref.watch(earningsCalculatorProvider);
  final currency = ref.watch(currencyProvider).code;
  final nowMicros = ref.watch(clockProvider).now().microsecondsSinceEpoch;
  return calc.summarize(snap, range, nowMicros, currencyCode: currency);
});
