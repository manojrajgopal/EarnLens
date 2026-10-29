import '../../core/date_time/local_date.dart';
import '../models/enums.dart';
import '../models/income_source.dart';
import '../models/records.dart';
import 'accrual_engine.dart';
import 'source_rules.dart';

enum PaymentStatus {
  upcoming,
  dueToday,
  overdue,
  partiallyReceived,
  received;

  String get label => switch (this) {
        upcoming => 'Upcoming',
        dueToday => 'Due today',
        overdue => 'Overdue',
        partiallyReceived => 'Partially received',
        received => 'Received',
      };
}

/// A payment the user expects for a given earning period.
class ExpectedPayment {
  const ExpectedPayment({
    required this.sourceId,
    required this.title,
    required this.periodMonth,
    required this.dueDate,
    required this.expectedMinor,
    required this.receivedMinor,
    required this.status,
    this.itemId,
  });

  final String sourceId;
  final String? itemId;
  final String title;
  final YearMonth periodMonth;
  final LocalDate dueDate;
  final int expectedMinor;
  final int receivedMinor;
  final PaymentStatus status;

  int get outstandingMinor => (expectedMinor - receivedMinor).clamp(0, 1 << 52);

  /// Stable key used for de-duplicating notifications and payments.
  String get key => itemId != null ? 'item:$itemId' : 'pay:$sourceId:${periodMonth.toIso()}';
}

/// Derives expected payment dates from each source's explicit payment rule.
/// Accrual periods and payment dates are deliberately separate: October's
/// salary belongs to October even when it is paid in November.
class PaymentScheduler {
  const PaymentScheduler(this.engine);

  final AccrualEngine engine;

  /// Due date for the pay of [period] under the source's rule, or null for manual rules.
  static LocalDate? dueDateFor(IncomeSource s, YearMonth period, {Set<LocalDate> holidays = const {}}) {
    final LocalDate base;
    switch (s.payRule) {
      case PayRule.manual:
        return s.expectedPayDate;
      case PayRule.lastDayOfMonth:
        base = period.addMonths(s.payOffsetMonths).lastDay;
      case PayRule.dayOfMonth:
        final m = period.addMonths(s.payOffsetMonths);
        base = LocalDate(m.year, m.month, s.payDay.clamp(1, m.lengthInDays));
    }
    return adjustForWeekend(base, s.weekendAdjust, s.schedule.weekdays, holidays);
  }

  static LocalDate adjustForWeekend(
    LocalDate date,
    WeekendAdjust adjust,
    Set<int> workingWeekdays,
    Set<LocalDate> holidays,
  ) {
    if (adjust == WeekendAdjust.none || workingWeekdays.isEmpty) return date;
    bool ok(LocalDate d) => workingWeekdays.contains(d.weekday) && !holidays.contains(d);
    var d = date;
    final step = adjust == WeekendAdjust.previousBusinessDay ? -1 : 1;
    for (var i = 0; i < 14 && !ok(d); i++) {
      d = d.addDays(step);
    }
    return d;
  }

  /// Expected payments for rule-based sources whose earning period lies in
  /// [periods], plus dated compensation items.
  List<ExpectedPayment> expectedPayments({
    required List<SourceRules> rules,
    required List<CompensationItem> items,
    required List<LedgerEntry> ledger,
    required Iterable<YearMonth> periods,
    required LocalDate today,
  }) {
    final result = <ExpectedPayment>[];
    final receivedByKey = _receivedByPeriod(ledger);
    final receivedByItem = _receivedByItem(ledger);

    for (final r in rules) {
      final s = r.source;
      if (!s.kind.accruesContinuously) continue;
      final holidays = r.holidayDates;
      if (s.kind == IncomeKind.temporary && (s.payRule == PayRule.manual || s.usesFixedTotal)) {
        // Temporary work is paid once for the whole engagement.
        final end = s.endDate;
        final due = s.expectedPayDate ?? (end == null ? null : dueDateFor(s, end.yearMonth));
        if (end == null || due == null) continue;
        if (!periods.contains(end.yearMonth) && !periods.contains(due.yearMonth)) continue;
        final expected = engine
            .accruedForDates(r, DateRange(s.startDate, end.addDays(1)))
            .roundToInt();
        var received = 0;
        for (final e in receivedByKey.entries) {
          if (e.key.startsWith('${s.id}|')) received += e.value;
        }
        result.add(_build(s.id, null, s.name, end.yearMonth, due, expected, received, today));
        continue;
      }
      for (final p in periods) {
        final due = dueDateFor(s, p, holidays: holidays);
        if (due == null) continue;
        final expected = engine.accruedForDates(r, DateRange.month(p)).roundToInt();
        if (expected <= 0) continue;
        final received = receivedByKey['${s.id}|${p.toIso()}'] ?? 0;
        result.add(_build(s.id, null, '${s.name} · ${_monthName(p)}', p, due, expected, received, today));
      }
    }

    for (final item in items) {
      if (item.cancelled || item.nonCash) continue;
      final due = item.expectedDate ?? item.earnedDate;
      if (due == null || !periods.contains(due.yearMonth)) continue;
      final expected = item.actualMinor ?? item.expectedMinor;
      if (expected == null || expected <= 0) continue;
      result.add(_build(
        item.sourceId ?? '',
        item.id,
        item.title,
        due.yearMonth,
        due,
        expected,
        receivedByItem[item.id] ?? 0,
        today,
      ));
    }
    result.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return result;
  }

  static ExpectedPayment _build(
    String sourceId,
    String? itemId,
    String title,
    YearMonth period,
    LocalDate due,
    int expected,
    int received,
    LocalDate today,
  ) {
    final PaymentStatus status;
    if (received >= expected) {
      status = PaymentStatus.received;
    } else if (received > 0) {
      status = PaymentStatus.partiallyReceived;
    } else if (due.isBefore(today)) {
      status = PaymentStatus.overdue;
    } else if (due == today) {
      status = PaymentStatus.dueToday;
    } else {
      status = PaymentStatus.upcoming;
    }
    return ExpectedPayment(
      sourceId: sourceId,
      itemId: itemId,
      title: title,
      periodMonth: period,
      dueDate: due,
      expectedMinor: expected,
      receivedMinor: received,
      status: status,
    );
  }

  /// Net cash received per `sourceId|period` (receipts minus reversals,
  /// plus deductions, which count as settled because they were withheld).
  static Map<String, int> _receivedByPeriod(List<LedgerEntry> ledger) {
    final map = <String, int>{};
    for (final e in ledger) {
      if (!e.status.counts || e.itemId != null) continue;
      final sign = switch (e.type) {
        LedgerType.received || LedgerType.deduction => 1,
        LedgerType.reversal => -1,
        _ => 0,
      };
      if (sign == 0) continue;
      final k = '${e.sourceId}|${e.periodMonth.toIso()}';
      map[k] = (map[k] ?? 0) + sign * e.amountMinor;
    }
    return map;
  }

  static Map<String, int> _receivedByItem(List<LedgerEntry> ledger) {
    final map = <String, int>{};
    for (final e in ledger) {
      if (!e.status.counts || e.itemId == null) continue;
      final sign = switch (e.type) {
        LedgerType.received || LedgerType.deduction => 1,
        LedgerType.reversal => -1,
        _ => 0,
      };
      map[e.itemId!] = (map[e.itemId!] ?? 0) + sign * e.amountMinor;
    }
    return map;
  }

  static String _monthName(YearMonth m) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${names[m.month - 1]} ${m.year}';
  }
}
