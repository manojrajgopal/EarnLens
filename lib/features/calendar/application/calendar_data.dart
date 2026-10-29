import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/date_time/local_date.dart';
import '../../../domain/calculation/payment_schedule.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/income_source.dart';
import '../../../domain/models/records.dart';

/// Visual category of a calendar entry; mapped to colours in the UI and
/// listed in the legend.
enum CalTone {
  upcoming,
  overdue,
  partial,
  received,
  compensation,
  transaction,
  work,
  checkIn,
  userEvent;

  String get label => switch (this) {
        upcoming => 'Expected payment',
        overdue => 'Overdue payment',
        partial => 'Partly paid',
        received => 'Received',
        compensation => 'Bonus or one-time income',
        transaction => 'Recorded transaction',
        work => 'Temporary work',
        checkIn => 'Month-end check-in',
        userEvent => 'Your event',
      };

  static CalTone forStatus(PaymentStatus s) => switch (s) {
        PaymentStatus.upcoming || PaymentStatus.dueToday => upcoming,
        PaymentStatus.overdue => overdue,
        PaymentStatus.partiallyReceived => partial,
        PaymentStatus.received => received,
      };
}

/// One thing that happens on a calendar day. Built only from persisted data.
class CalEntry {
  const CalEntry({
    required this.tone,
    required this.title,
    required this.subtitle,
    this.amountMinor,
    this.currencyCode,
    this.sourceId,
    this.period,
    this.itemId,
    this.payment,
    this.event,
    this.reconcile = false,
  });

  final CalTone tone;
  final String title;
  final String subtitle;
  final int? amountMinor;
  final String? currencyCode;
  final String? sourceId;
  final YearMonth? period;
  final String? itemId;
  final ExpectedPayment? payment;
  final CalendarEvent? event;

  /// Variable-income month-end reminder (opens the month record).
  final bool reconcile;

  /// Payment that can still be marked as received.
  bool get canMarkReceived =>
      payment != null && payment!.status != PaymentStatus.received && (sourceId?.isNotEmpty ?? false);
}

class CalendarMonthData {
  const CalendarMonthData({required this.month, required this.entries, required this.workShade});
  final YearMonth month;
  final Map<LocalDate, List<CalEntry>> entries;

  /// Days covered by temporary work, with the source(s) working that day.
  final Map<LocalDate, List<IncomeSource>> workShade;

  List<CalEntry> on(LocalDate d) => entries[d] ?? const [];
}

final calendarMonthProvider = Provider.autoDispose.family<CalendarMonthData, YearMonth>((ref, month) {
  final snap = ref.watch(snapshotProvider);
  final today = ref.watch(todayProvider);
  final scheduler = ref.watch(paymentSchedulerProvider);
  final userEvents = ref.watch(calendarEventsProvider).value ?? const <CalendarEvent>[];
  final range = DateRange.month(month);
  final entries = <LocalDate, List<CalEntry>>{};
  void add(LocalDate d, CalEntry e) {
    if (range.contains(d)) (entries[d] ??= []).add(e);
  }

  String? currencyOf(String? sourceId) => sourceId == null ? null : snap.source(sourceId)?.currencyCode;
  String nameOf(String? sourceId) => (sourceId == null ? null : snap.source(sourceId)?.name) ?? 'Income';

  // Expected payments due this month. Earning periods up to six months back
  // are included because pay can arrive months after the work.
  final payments = scheduler.expectedPayments(
    rules: snap.rules.values.toList(),
    items: snap.items,
    ledger: snap.ledger,
    periods: [for (var i = -6; i <= 0; i++) month.addMonths(i)],
    today: today,
  );
  final paymentItemDates = <String>{};
  for (final p in payments) {
    if (!range.contains(p.dueDate)) continue;
    final item = p.itemId == null ? null : snap.items.where((i) => i.id == p.itemId).firstOrNull;
    if (p.itemId != null) paymentItemDates.add('${p.itemId}|${p.dueDate.toIso()}');
    add(
      p.dueDate,
      CalEntry(
        tone: item != null ? (p.status == PaymentStatus.upcoming ? CalTone.compensation : CalTone.forStatus(p.status))
            : CalTone.forStatus(p.status),
        title: p.title,
        subtitle: p.itemId == null ? 'Pay for ${_monthName(p.periodMonth)} · ${p.status.label}' : p.status.label,
        amountMinor: p.status == PaymentStatus.partiallyReceived ? p.outstandingMinor : p.expectedMinor,
        currencyCode: item?.currencyCode ?? currencyOf(p.sourceId),
        sourceId: p.sourceId.isEmpty ? null : p.sourceId,
        period: p.periodMonth,
        itemId: p.itemId,
        payment: p,
      ),
    );
  }

  // Compensation item dates not already shown as a payment.
  for (final i in snap.items) {
    if (i.cancelled) continue;
    final dates = <(LocalDate, String)>[
      if (i.expectedDate != null) (i.expectedDate!, 'Expected'),
      if (i.isEarned) (i.earnedDate!, 'Earned'),
    ];
    final seen = <LocalDate>{};
    for (final (d, label) in dates) {
      if (!seen.add(d) || paymentItemDates.contains('${i.id}|${d.toIso()}')) continue;
      add(
        d,
        CalEntry(
          tone: CalTone.compensation,
          title: i.title,
          subtitle: '${i.type.label} · $label${i.nonCash ? ' · non-cash' : ''}',
          amountMinor: label == 'Earned' ? i.actualMinor : (i.expectedMinor ?? i.actualMinor),
          currencyCode: i.currencyCode,
          sourceId: i.sourceId,
          itemId: i.id,
        ),
      );
    }
  }

  // Temporary work periods.
  final shade = <LocalDate, List<IncomeSource>>{};
  for (final s in snap.sources) {
    if (s.kind != IncomeKind.temporary) continue;
    final end = s.endDate ?? (s.status == SourceStatus.active ? range.endExclusive.addDays(-1) : s.startDate);
    final span = DateRange(s.startDate, end.addDays(1).max(s.startDate)).intersect(range);
    if (span != null) {
      for (final d in span.days) {
        (shade[d] ??= []).add(s);
      }
    }
    add(s.startDate, CalEntry(tone: CalTone.work, title: '${s.name} starts', subtitle: 'Temporary work', sourceId: s.id));
    if (s.endDate != null) {
      add(s.endDate!, CalEntry(tone: CalTone.work, title: '${s.name} ends', subtitle: 'Last working day', sourceId: s.id));
    }
  }

  // Recorded ledger entries.
  for (final e in snap.ledger) {
    if (!e.status.counts || !range.contains(e.date)) continue;
    add(
      e.date,
      CalEntry(
        tone: CalTone.transaction,
        title: '${e.type.label} · ${nameOf(e.sourceId)}',
        subtitle: 'For ${_monthName(e.periodMonth)}${e.notes?.isNotEmpty ?? false ? ' · ${e.notes}' : ''}',
        amountMinor: e.amountMinor,
        currencyCode: e.currencyCode,
        sourceId: e.sourceId,
        period: e.periodMonth,
      ),
    );
  }

  // Month-end reconciliation reminders for variable income without an actual.
  if (!month.isAfter(today.yearMonth)) {
    for (final s in snap.sources) {
      if (s.kind != IncomeKind.variable || s.status != SourceStatus.active) continue;
      if (month.isBefore(s.startDate.yearMonth)) continue;
      if (s.endDate != null && month.isAfter(s.endDate!.yearMonth)) continue;
      if (snap.record(s.id, month)?.actualMinor != null) continue;
      add(
        month.lastDay,
        CalEntry(
          tone: CalTone.checkIn,
          title: 'Record ${s.name} for ${_monthName(month)}',
          subtitle: 'Enter what you actually earned this month',
          sourceId: s.id,
          period: month,
          reconcile: true,
        ),
      );
    }
  }

  // The user's own events.
  for (final ev in userEvents) {
    if (ev.cancelled) continue;
    add(
      ev.date,
      CalEntry(
        tone: CalTone.userEvent,
        title: ev.title,
        subtitle: [ev.type.label, if (ev.remind) 'Reminder on', if (ev.sourceId != null) nameOf(ev.sourceId)]
            .join(' · '),
        amountMinor: ev.amountMinor,
        currencyCode: currencyOf(ev.sourceId),
        sourceId: ev.sourceId,
        event: ev,
      ),
    );
  }

  for (final list in entries.values) {
    list.sort((a, b) => a.tone.index.compareTo(b.tone.index));
  }
  return CalendarMonthData(month: month, entries: entries, workShade: shade);
});

String _monthName(YearMonth m) {
  const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${names[m.month - 1]} ${m.year}';
}
