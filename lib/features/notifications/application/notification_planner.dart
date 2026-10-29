import '../../../core/date_time/local_date.dart';
import '../../../core/formatting/money_format.dart';
import '../../../domain/calculation/financial_calendar.dart';
import '../../../domain/calculation/payment_schedule.dart';
import '../../../domain/calculation/earnings_snapshot.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/records.dart';
import '../../../domain/models/settings.dart';
import '../domain/notification_models.dart';
import '../templates/notification_templates.dart';

/// Pure rules deciding which local notifications to schedule.
///
/// * Only future instants within [horizonDays] are planned.
/// * Each event has a stable key, so re-planning replaces rather than duplicates.
/// * Reminder times falling inside quiet hours move to the end of quiet hours.
class NotificationPlanner {
  const NotificationPlanner(this.calendar, {this.horizonDays = 45});

  final FinancialCalendar calendar;
  final int horizonDays;

  List<PlannedNotification> plan({
    required EarningsSnapshot snapshot,
    required List<ExpectedPayment> payments,
    required List<CalendarEvent> events,
    required NotificationSettings settings,
    required BackupState backup,
    required int nowMicros,
    required MoneyFormatter money,
    required bool privacyMode,
    int monthEndOffsetDays = 0,
    String? earnedThisMonth,
  }) {
    if (!settings.masterEnabled) return const [];
    final today = calendar.dateOf(nowMicros);
    final horizon = today.addDays(horizonDays);
    final out = <PlannedNotification>[];
    String? amount(int minor) => privacyMode ? null : money.minor(minor);

    void add(String key, NotificationCategory c, LocalDate day, (String, String) text, {String route = '/'}) {
      if (!settings.isOn(c)) return;
      if (day.isAfter(horizon)) return;
      final at = _reminderInstant(day, settings);
      if (at <= nowMicros) return;
      out.add(PlannedNotification(key: key, category: c, title: text.$1, body: text.$2, atMicros: at, route: route));
    }

    for (final p in payments) {
      final source = snapshot.source(p.sourceId);
      if (p.itemId != null) {
        if (p.status == PaymentStatus.upcoming || p.status == PaymentStatus.dueToday) {
          add('bonus:${p.itemId}', NotificationCategory.upcomingBonus, p.dueDate.addDays(-settings.daysBefore),
              NotificationTemplates.upcomingBonus(p.title, p.dueDate),
              route: '/income/${p.sourceId}');
        }
        continue;
      }
      final isSalaryLike = source != null && source.kind != IncomeKind.variable;
      if (!isSalaryLike) continue;
      switch (p.status) {
        case PaymentStatus.upcoming:
          add('${p.key}:before', NotificationCategory.upcomingSalary, p.dueDate.addDays(-settings.daysBefore),
              NotificationTemplates.upcomingSalary(p.title, p.dueDate, amount(p.expectedMinor)),
              route: '/income/${p.sourceId}');
          add('${p.key}:due', NotificationCategory.salaryPayday, p.dueDate,
              NotificationTemplates.payday(p.title, amount(p.expectedMinor)),
              route: '/income/${p.sourceId}');
        case PaymentStatus.dueToday:
          add('${p.key}:due', NotificationCategory.salaryPayday, p.dueDate,
              NotificationTemplates.payday(p.title, amount(p.expectedMinor)),
              route: '/income/${p.sourceId}');
          add('${p.key}:overdue', NotificationCategory.outstandingPayment, p.dueDate.addDays(1),
              NotificationTemplates.overdue(p.title),
              route: '/income/${p.sourceId}');
        case PaymentStatus.overdue:
          add('${p.key}:overdue', NotificationCategory.outstandingPayment, today.addDays(1),
              NotificationTemplates.overdue(p.title),
              route: '/income/${p.sourceId}');
        case PaymentStatus.partiallyReceived:
        case PaymentStatus.received:
          break;
      }
    }

    for (final s in snapshot.sources) {
      if (s.status == SourceStatus.archived) continue;
      final end = s.endDate;
      if (s.kind == IncomeKind.temporary && end != null && !end.isBefore(today)) {
        add('tempEnd:${s.id}:$end', NotificationCategory.temporaryJobEnd, end.addDays(-settings.daysBefore),
            NotificationTemplates.temporaryEnding(s.name, end),
            route: '/income/${s.id}');
      }
      if (s.kind == IncomeKind.variable && s.status == SourceStatus.active) {
        final month = today.yearMonth;
        if (snapshot.record(s.id, month)?.actualMinor == null) {
          add('actual:${s.id}:$month', NotificationCategory.monthlyActualUpdate, month.next.firstDay,
              NotificationTemplates.monthlyActual(s.name, month),
              route: '/income/${s.id}');
        }
      }
    }

    final month = today.yearMonth;
    for (final m in [month, month.next]) {
      add('monthEnd:$m', NotificationCategory.monthEndReview, m.lastDay.addDays(-monthEndOffsetDays),
          NotificationTemplates.monthEnd(m),
          route: '/insights');
    }

    final last = backup.lastBackupAt;
    final LocalDate backupDay;
    final int daysSince;
    if (last == null) {
      backupDay = today.addDays(1);
      daysSince = -1;
    } else {
      final lastDay = calendar.dateOf(last.microsecondsSinceEpoch);
      final due = lastDay.addDays(backup.reminderDays);
      backupDay = due.isAfter(today) ? due : today.addDays(1);
      daysSince = lastDay.daysUntil(backupDay);
    }
    add('backup:$backupDay', NotificationCategory.backupReminder, backupDay, NotificationTemplates.backup(daysSince),
        route: '/settings/data');

    final weekly = settings.summaryFrequency == SummaryFrequency.weekly;
    var summaryDay = today.addDays(1);
    if (weekly) {
      while (summaryDay.weekday != 7) {
        summaryDay = summaryDay.addDays(1);
      }
    }
    add('summary:$summaryDay', NotificationCategory.earningsSummary, summaryDay,
        NotificationTemplates.summary(weekly, privacyMode ? null : earnedThisMonth));

    for (final e in events) {
      if (!e.remind || e.cancelled) continue;
      add('event:${e.id}:${e.date}', NotificationCategory.calendarReminder, e.date,
          NotificationTemplates.calendar(e.title),
          route: '/calendar');
    }

    out.sort((a, b) => a.atMicros.compareTo(b.atMicros));
    // Keep within platform limits (iOS allows 64 pending notifications).
    return out.length > 60 ? out.sublist(0, 60) : out;
  }

  int _reminderInstant(LocalDate day, NotificationSettings s) {
    var minute = s.reminderMinute;
    if (_inQuietHours(minute, s.quietStartMinute, s.quietEndMinute)) minute = s.quietEndMinute;
    return calendar.localTimeMicros(day, minute);
  }

  static bool _inQuietHours(int minute, int start, int end) {
    if (start == end) return false;
    return start < end ? minute >= start && minute < end : minute >= start || minute < end;
  }
}
