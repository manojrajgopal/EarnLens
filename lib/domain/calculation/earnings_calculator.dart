import '../../core/date_time/local_date.dart';
import '../models/enums.dart';
import '../models/income_source.dart';
import '../money/fraction.dart';
import 'accrual_engine.dart';
import 'earnings_snapshot.dart';
import 'rate_calculator.dart';

/// Per-source figures for a date range. All values are minor units.
///
/// * [expected]   – what the plan says the range should earn in total
/// * [accrued]    – money earned so far ("earned so far"), exact
/// * [actual]     – best known earnings so far (accrued + adjustments, or
///                  recorded actuals for variable income)
/// * [received]   – cash received for this range's earning periods
/// * [deductions] – amounts withheld from pay (tax, provident fund)
/// * [outstanding]– earned but not yet received or withheld
class SourceSummary {
  SourceSummary({
    required this.source,
    required this.expected,
    required this.accrued,
    required this.actual,
    required this.received,
    required this.deductions,
    required this.adjustments,
    required this.hasActual,
  });

  final IncomeSource source;
  final int expected;
  final Fraction accrued;
  final int actual;
  final int received;
  final int deductions;
  final int adjustments;

  /// False for variable income without any recorded actual yet.
  final bool hasActual;

  int get outstanding => actual - received - deductions;
  int get variance => actual - expected;
}

class PeriodSummary {
  PeriodSummary(this.range, this.sources);

  final DateRange range;
  final List<SourceSummary> sources;

  int _sum(int Function(SourceSummary s) f) => sources.fold(0, (a, s) => a + f(s));

  int get expected => _sum((s) => s.expected);
  int get actual => _sum((s) => s.actual);
  int get received => _sum((s) => s.received);
  int get deductions => _sum((s) => s.deductions);
  int get outstanding => _sum((s) => s.outstanding);
  int get variance => actual - expected;
  Fraction get accrued => Fraction.sum(sources.map((s) => s.accrued));
}

/// Builds summaries and live totals from an [EarningsSnapshot].
class EarningsCalculator {
  EarningsCalculator(this.engine) : rates = RateCalculator(engine);

  final AccrualEngine engine;
  final RateCalculator rates;

  /// Sources whose currency matches [currencyCode] (totals never mix currencies).
  Iterable<IncomeSource> _sourcesFor(EarningsSnapshot snap, String currencyCode, Set<String>? only) =>
      snap.sources.where((s) => s.currencyCode == currencyCode && (only == null || only.contains(s.id)));

  PeriodSummary summarize(
    EarningsSnapshot snap,
    DateRange range,
    int nowMicros, {
    required String currencyCode,
    Set<String>? sourceIds,
  }) {
    final today = engine.calendar.dateOf(nowMicros);
    final list = <SourceSummary>[];
    for (final s in _sourcesFor(snap, currencyCode, sourceIds)) {
      list.add(summarizeSource(snap, s, range, nowMicros, today));
    }
    return PeriodSummary(range, list);
  }

  SourceSummary summarizeSource(
    EarningsSnapshot snap,
    IncomeSource s,
    DateRange range,
    int nowMicros,
    LocalDate today,
  ) {
    final r = snap.rules[s.id]!;
    var expected = 0;
    var accrued = Fraction.zero;
    var hasActual = true;

    if (s.kind.accruesContinuously) {
      expected = engine.accruedForDates(r, range).roundToInt();
      accrued = engine.accruedInRangeAsOf(r, range, nowMicros);
    } else if (s.kind == IncomeKind.variable) {
      var actualSum = 0;
      var anyActual = false;
      for (final m in _monthsOverlapping(range)) {
        if (m.isBefore(s.startDate.yearMonth)) continue;
        if (s.endDate != null && m.isAfter(s.endDate!.yearMonth)) continue;
        final share = _monthShare(m, range);
        final est = snap.variableExpected(s.id, m);
        if (est != null) expected += (Fraction.fromInt(est) * share).roundToInt();
        if (m.firstDay.isAfter(today)) continue;
        final act = share == Fraction.one
            ? snap.variableActual(s.id, m, upTo: today)
            : _partialVariableActual(snap, s.id, m, range, today);
        if (act != null) {
          anyActual = true;
          actualSum += act;
        }
      }
      accrued = Fraction.fromInt(actualSum);
      hasActual = anyActual;
    }

    // Compensation items (bonuses, one-time income, benefits).
    for (final item in snap.itemsFor(s.id)) {
      if (!item.countsAsEarnings) continue;
      final plan = item.planningDate;
      if (plan != null && range.contains(plan)) {
        expected += item.expectedMinor ?? item.actualMinor ?? 0;
      }
      if (item.isEarned && range.contains(item.earnedDate!) && !item.earnedDate!.isAfter(today)) {
        accrued += Fraction.fromInt(item.actualMinor!);
      }
    }

    var received = 0;
    var deductions = 0;
    var adjustments = 0;
    // Month-aligned ranges attribute entries to the earning period they belong
    // to (October salary paid in November counts for October); custom ranges
    // use the entry date.
    final partial = _isPartial(range);
    for (final e in snap.ledgerFor(s.id)) {
      final inPeriod = partial ? range.contains(e.date) : range.contains(e.periodMonth.firstDay);
      if (!inPeriod) continue;
      switch (e.type) {
        case LedgerType.received:
          received += e.amountMinor;
        case LedgerType.reversal:
          received -= e.amountMinor;
        case LedgerType.deduction:
          deductions += e.amountMinor;
        case LedgerType.adjustment:
          adjustments += e.amountMinor;
        case LedgerType.earned:
          break; // handled via variableActual / not applicable to rule-based sources
      }
    }

    final actual = accrued.roundToInt() + adjustments;
    return SourceSummary(
      source: s,
      expected: expected,
      accrued: accrued + Fraction.fromInt(adjustments),
      actual: actual,
      received: received,
      deductions: deductions,
      adjustments: adjustments,
      hasActual: hasActual || adjustments != 0,
    );
  }

  /// Live "earned so far" for [range]: continuous accrual plus recorded
  /// variable actuals, earned items and adjustments up to [nowMicros].
  Fraction liveTotal(
    EarningsSnapshot snap,
    DateRange range,
    int nowMicros, {
    required String currencyCode,
    Set<String>? sourceIds,
  }) =>
      summarize(snap, range, nowMicros, currencyCode: currencyCode, sourceIds: sourceIds).accrued;

  /// Combined nominal rate of all rule-based sources for [unit].
  Fraction combinedRate(
    EarningsSnapshot snap,
    EarningUnit unit,
    LocalDate ref, {
    required String currencyCode,
    RateBasis basis = RateBasis.calendarTime,
    Set<String>? sourceIds,
  }) {
    var total = Fraction.zero;
    for (final s in _sourcesFor(snap, currencyCode, sourceIds)) {
      if (!s.kind.accruesContinuously) continue;
      total += rates.rate(snap.rules[s.id]!, unit, ref, basis: basis);
    }
    return total;
  }

  /// One summary per month, oldest first.
  List<PeriodSummary> monthlySeries(
    EarningsSnapshot snap,
    YearMonth last,
    int count,
    int nowMicros, {
    required String currencyCode,
    Set<String>? sourceIds,
  }) =>
      [
        for (var i = count - 1; i >= 0; i--)
          summarize(snap, DateRange.month(last.addMonths(-i)), nowMicros,
              currencyCode: currencyCode, sourceIds: sourceIds),
      ];

  static Iterable<YearMonth> _monthsOverlapping(DateRange range) sync* {
    if (range.lengthInDays == 0) return;
    var m = range.start.yearMonth;
    final last = range.endExclusive.addDays(-1).yearMonth;
    while (!m.isAfter(last)) {
      yield m;
      m = m.next;
    }
  }

  static Fraction _monthShare(YearMonth m, DateRange range) {
    final overlap = range.intersect(DateRange.month(m));
    if (overlap == null) return Fraction.zero;
    return Fraction.fromInt(overlap.lengthInDays, m.lengthInDays);
  }

  static bool _isPartial(DateRange range) =>
      range.start.day != 1 || range.endExclusive.day != 1;

  int? _partialVariableActual(EarningsSnapshot snap, String id, YearMonth m, DateRange range, LocalDate today) {
    final rec = snap.record(id, m);
    final overlap = range.intersect(DateRange.month(m))!;
    if (rec?.actualMinor != null) {
      // Monthly total known only in aggregate: prorate by days (documented).
      return (Fraction.fromInt(rec!.actualMinor!) * _monthShare(m, range)).roundToInt();
    }
    final sum = snap.earnedEntries(id, overlap, upTo: today);
    return sum == 0 ? null : sum;
  }
}
