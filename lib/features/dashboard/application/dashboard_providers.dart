import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/date_time/local_date.dart';
import '../../../domain/calculation/earnings_calculator.dart';
import '../../../domain/calculation/forecast_calculator.dart';
import '../../../domain/calculation/payment_schedule.dart';
import '../../../domain/calculation/rate_calculator.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/records.dart';
import '../../../domain/models/settings.dart';
import '../../../domain/money/fraction.dart';

/// Source filter for a dashboard card (null = all sources).
Set<String>? cardSources(Ref ref, DashboardCardType type) =>
    ref.watch(dashboardConfigProvider).cards.firstWhere((c) => c.type == type).sourceIds;

DateRange counterRangeFor(CounterRange r, LocalDate today) => switch (r) {
      CounterRange.today => DateRange(today, today.addDays(1)),
      CounterRange.month => DateRange.month(today.yearMonth),
      CounterRange.year => DateRange.year(today.year),
    };

int _now(Ref ref) => ref.watch(clockProvider).now().microsecondsSinceEpoch;

/// Live "now": figures that include the current, still-accruing period watch
/// this so they update every second without a refresh.
int _liveNow(Ref ref) => ref.watch(liveNowProvider).microsecondsSinceEpoch;

/// Current-month summary, updated live as earnings accrue.
final monthSummaryProvider = Provider.family<PeriodSummary, DashboardCardType>((ref, type) {
  final today = ref.watch(todayProvider);
  return ref.watch(earningsCalculatorProvider).summarize(
        ref.watch(snapshotProvider),
        DateRange.month(today.yearMonth),
        _liveNow(ref),
        currencyCode: ref.watch(currencyProvider).code,
        sourceIds: cardSources(ref, type),
      );
});

final lastMonthSummaryProvider = Provider<PeriodSummary>((ref) {
  final today = ref.watch(todayProvider);
  return ref.watch(earningsCalculatorProvider).summarize(
        ref.watch(snapshotProvider),
        DateRange.month(today.yearMonth.previous),
        _now(ref),
        currencyCode: ref.watch(currencyProvider).code,
        sourceIds: cardSources(ref, DashboardCardType.expectedVsActual),
      );
});

final ratesProvider = Provider<Map<EarningUnit, Fraction>>((ref) {
  final cfg = ref.watch(dashboardConfigProvider);
  final calc = ref.watch(earningsCalculatorProvider);
  final snap = ref.watch(snapshotProvider);
  final today = ref.watch(todayProvider);
  final currency = ref.watch(currencyProvider).code;
  final only = cardSources(ref, DashboardCardType.rates);
  return {
    for (final u in EarningUnit.values)
      u: calc.combinedRate(snap, u, today, currencyCode: currency, basis: cfg.rateBasis, sourceIds: only),
  };
});

/// Completed months before this one (static; recomputed when data changes).
final _trendHistoryProvider = Provider.family<List<PeriodSummary>, int>((ref, months) {
  final today = ref.watch(todayProvider);
  return ref.watch(earningsCalculatorProvider).monthlySeries(
        ref.watch(snapshotProvider),
        today.yearMonth.previous,
        months - 1,
        _now(ref),
        currencyCode: ref.watch(currencyProvider).code,
        sourceIds: cardSources(ref, DashboardCardType.trend),
      );
});

/// Monthly series ending this month; the argument is the number of months.
/// Only the current month is recomputed on each live tick.
final trendProvider = Provider.family<List<PeriodSummary>, int>((ref, months) {
  final today = ref.watch(todayProvider);
  return [
    ...ref.watch(_trendHistoryProvider(months)),
    ref.watch(earningsCalculatorProvider).summarize(
          ref.watch(snapshotProvider),
          DateRange.month(today.yearMonth),
          _liveNow(ref),
          currencyCode: ref.watch(currencyProvider).code,
          sourceIds: cardSources(ref, DashboardCardType.trend),
        ),
  ];
});

/// Summary for any month (expected vs actual card month switcher); live for
/// the current month.
final monthSummaryForProvider = Provider.family<PeriodSummary, YearMonth>((ref, month) {
  final current = month == ref.watch(todayProvider).yearMonth;
  return ref.watch(earningsCalculatorProvider).summarize(
        ref.watch(snapshotProvider),
        DateRange.month(month),
        current ? _liveNow(ref) : _now(ref),
        currencyCode: ref.watch(currencyProvider).code,
        sourceIds: cardSources(ref, DashboardCardType.expectedVsActual),
      );
});

class QuickStats {
  const QuickStats({required this.receivedThisMonth, required this.upcoming, required this.overdue});

  /// Completed "payment received" entries dated this month.
  final int receivedThisMonth;
  final int upcoming;
  final int overdue;
}

final quickStatsProvider = Provider<QuickStats>((ref) {
  final month = DateRange.month(ref.watch(todayProvider).yearMonth);
  final received = ref
      .watch(snapshotProvider)
      .ledger
      .where((e) => e.type == LedgerType.received && e.status.counts && month.contains(e.date))
      .length;
  final payments = ref.watch(expectedPaymentsProvider);
  return QuickStats(
    receivedThisMonth: received,
    upcoming: payments.where((p) => p.status == PaymentStatus.upcoming || p.status == PaymentStatus.dueToday).length,
    overdue: payments.where((p) => p.status == PaymentStatus.overdue || p.status == PaymentStatus.partiallyReceived).length,
  );
});

final yearSummaryProvider = Provider.family<PeriodSummary, (int, DashboardCardType)>((ref, args) {
  final (year, type) = args;
  final today = ref.watch(todayProvider);
  // Same-length window for fair year-over-year comparison.
  final end = year == today.year
      ? today.addDays(1)
      : LocalDate(year, today.month, today.day.clamp(1, LocalDate.daysInMonth(year, today.month))).addDays(1);
  return ref.watch(earningsCalculatorProvider).summarize(
        ref.watch(snapshotProvider),
        DateRange(LocalDate(year, 1, 1), end),
        // Year to date accrues live; earlier years are fixed.
        year == today.year ? _liveNow(ref) : _now(ref),
        currencyCode: ref.watch(currencyProvider).code,
        sourceIds: cardSources(ref, type),
      );
});

final monthForecastProvider = Provider<Forecast>((ref) {
  final today = ref.watch(todayProvider);
  return ref.watch(forecastCalculatorProvider).forMonth(
        ref.watch(snapshotProvider),
        today.yearMonth,
        _liveNow(ref),
        currencyCode: ref.watch(currencyProvider).code,
        sourceIds: cardSources(ref, DashboardCardType.forecast),
      );
});

final yearForecastProvider = Provider<Forecast>((ref) {
  final today = ref.watch(todayProvider);
  return ref.watch(forecastCalculatorProvider).forYear(
        ref.watch(snapshotProvider),
        today.year,
        _liveNow(ref),
        currencyCode: ref.watch(currencyProvider).code,
        sourceIds: cardSources(ref, DashboardCardType.forecast),
      );
});

/// Upcoming, due and overdue payments (oldest overdue first).
final openPaymentsProvider = Provider<List<ExpectedPayment>>((ref) {
  final only = cardSources(ref, DashboardCardType.upcomingPayments);
  return [
    for (final p in ref.watch(expectedPaymentsProvider))
      if (p.status != PaymentStatus.received && (only == null || only.contains(p.sourceId))) p,
  ];
});

final outstandingPaymentsProvider = Provider<List<ExpectedPayment>>((ref) {
  final only = cardSources(ref, DashboardCardType.outstanding);
  return [
    for (final p in ref.watch(expectedPaymentsProvider))
      if ((p.status == PaymentStatus.overdue || p.status == PaymentStatus.partiallyReceived) &&
          (only == null || only.contains(p.sourceId)))
        p,
  ];
});

final recentLedgerProvider = Provider<List<LedgerEntry>>((ref) {
  final entries = [...ref.watch(snapshotProvider).ledger]
    ..sort((a, b) {
      final c = b.date.compareTo(a.date);
      return c != 0 ? c : b.createdAt.compareTo(a.createdAt);
    });
  return entries.take(5).toList();
});

final bonusesThisYearProvider = Provider<List<CompensationItem>>((ref) {
  final year = ref.watch(todayProvider).year;
  final only = cardSources(ref, DashboardCardType.bonuses);
  return [
    for (final i in ref.watch(snapshotProvider).items)
      if (!i.cancelled &&
          i.type != CompensationType.oneTimeIncome &&
          i.planningDate?.year == year &&
          (only == null || only.contains(i.sourceId)))
        i,
  ]..sort((a, b) => a.planningDate!.compareTo(b.planningDate!));
});

/// Monthly rate now vs one year ago (rule-based income).
final growthProvider = Provider<(Fraction, Fraction)>((ref) {
  final calc = ref.watch(earningsCalculatorProvider);
  final snap = ref.watch(snapshotProvider);
  final today = ref.watch(todayProvider);
  final currency = ref.watch(currencyProvider).code;
  final only = cardSources(ref, DashboardCardType.growth);
  final yearAgo = today.addMonths(-12);
  return (
    calc.combinedRate(snap, EarningUnit.month, today, currencyCode: currency, sourceIds: only),
    calc.combinedRate(snap, EarningUnit.month, yearAgo, currencyCode: currency, sourceIds: only),
  );
});

class WeekEvent {
  const WeekEvent(this.date, this.title, this.kind, {this.route});
  final LocalDate date;
  final String title;
  final String kind;
  final String? route;
}

final weekEventsProvider = Provider<List<WeekEvent>>((ref) {
  final today = ref.watch(todayProvider);
  final week = DateRange(today, today.addDays(7));
  final out = <WeekEvent>[
    for (final p in ref.watch(expectedPaymentsProvider))
      if (week.contains(p.dueDate) && p.status != PaymentStatus.received)
        WeekEvent(p.dueDate, p.title, 'Payment', route: '/income/${p.sourceId}'),
    for (final e in ref.watch(calendarEventsProvider).value ?? const <CalendarEvent>[])
      if (!e.cancelled && week.contains(e.date)) WeekEvent(e.date, e.title, e.type.label, route: '/calendar'),
    for (final s in ref.watch(snapshotProvider).sources)
      if (s.kind == IncomeKind.temporary && s.endDate != null && week.contains(s.endDate!))
        WeekEvent(s.endDate!, '${s.name} ends', 'Temporary work', route: '/income/${s.id}'),
  ]..sort((a, b) => a.date.compareTo(b.date));
  return out;
});
