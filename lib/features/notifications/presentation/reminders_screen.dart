import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../database/app_database.dart';
import '../../../domain/calculation/payment_schedule.dart';
import '../../../domain/models/records.dart';
import '../../../shared/layout/page_layout.dart';
import '../../../shared/widgets/components.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../dashboard/presentation/dashboard_cards.dart';
import '../../refresh/application/app_refresher.dart';

/// Notifications that EarnLens has scheduled on this device (from the
/// notification_history table). "Scheduled" is not "delivered".
final scheduledRemindersProvider = StreamProvider<List<NotificationHistoryRow>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.notificationHistory)..orderBy([(t) => OrderingTerm.asc(t.scheduledFor)])).watch();
});

/// The bell in the dashboard header: what needs attention now, what is
/// coming up, and which reminders are scheduled.
class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(expectedPaymentsProvider);
    final today = ref.watch(todayProvider);
    final events = ref.watch(calendarEventsProvider).value ?? const <CalendarEvent>[];
    final now = ref.watch(clockProvider).now().microsecondsSinceEpoch;
    final scheduled = [
      for (final r in ref.watch(scheduledRemindersProvider).value ?? const <NotificationHistoryRow>[])
        if (r.scheduledFor > now) r,
    ];
    final enabled = ref.watch(notificationSettingsProvider).masterEnabled;
    final calendar = ref.watch(financialCalendarProvider);

    final attention = payments
        .where((p) => p.status == PaymentStatus.overdue || p.status == PaymentStatus.partiallyReceived)
        .toList();
    final soon = payments
        .where((p) =>
            (p.status == PaymentStatus.upcoming || p.status == PaymentStatus.dueToday) &&
            !p.dueDate.isAfter(today.addDays(30)))
        .toList();
    final upcomingEvents = events
        .where((e) => !e.cancelled && !e.date.isBefore(today) && !e.date.isAfter(today.addDays(30)))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders'), actions: [
        IconButton(
          tooltip: 'Notification settings',
          icon: const Icon(Icons.tune_rounded),
          onPressed: () => context.go('/settings/notifications'),
        ),
      ]),
      body: EarnPageList(
        onRefresh: () => ref.read(appRefresherProvider).refresh({RefreshScope.earnings, RefreshScope.calendar}),
        children: [
          if (!enabled)
            EarnCard(
              tint: context.colors.accentSoft,
              elevated: false,
              onTap: () => context.go('/settings/notifications'),
              child: Row(children: [
                Icon(Icons.notifications_off_outlined, color: context.colors.accentText),
                const SizedBox(width: 12),
                const Expanded(child: Text('Device reminders are off. Tap to turn on payday and overdue alerts.')),
              ]),
            ),
          SectionHeader('Needs attention (${attention.length})'),
          if (attention.isEmpty)
            _Quiet('Nothing overdue. Every expected payment so far has been recorded.')
          else
            EarnCard(child: Column(children: [for (final p in attention) PaymentRow(p)])),
          SectionHeader('Next 30 days (${soon.length + upcomingEvents.length})'),
          if (soon.isEmpty && upcomingEvents.isEmpty)
            _Quiet('No payments or events in the next 30 days.')
          else
            EarnCard(
              child: Column(children: [
                for (final p in soon) PaymentRow(p),
                for (final e in upcomingEvents)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_note_rounded),
                    title: Text(e.title),
                    subtitle: Text('${e.type.label} · ${formatDate(e.date)}${e.remind ? ' · reminder on' : ''}'),
                    onTap: () => context.go('/calendar'),
                  ),
              ]),
            ),
          SectionHeader('Scheduled on this device (${scheduled.length})'),
          if (scheduled.isEmpty)
            _Quiet(enabled ? 'No reminders are scheduled right now.' : 'Turn on reminders to schedule them.')
          else
            EarnCard(
              child: Column(children: [
                for (final r in scheduled.take(30))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.alarm_rounded),
                    title: Text(r.title),
                    subtitle: Text('Scheduled for ${formatDate(calendar.dateOf(r.scheduledFor))}'),
                  ),
              ]),
            ),
          const SizedBox(height: 8),
          Text(
            'Scheduled reminders are delivered by your device and may arrive a few minutes late. '
            'On the web they only appear while EarnLens is open.',
            style: AppType.caption.copyWith(color: context.colors.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _Quiet extends StatelessWidget {
  const _Quiet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Text(text, style: AppType.bodySmall.copyWith(color: context.colors.inkMuted)),
      );
}
