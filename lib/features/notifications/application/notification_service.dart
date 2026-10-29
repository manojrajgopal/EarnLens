import 'dart:async';

import 'package:drift/drift.dart' show InsertMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/date_time/local_date.dart';
import '../../../data/local/mappers.dart';
import '../../../database/app_database.dart';
import '../../../domain/models/records.dart';
import '../../../domain/models/settings.dart';
import '../domain/notification_models.dart';
import 'notification_planner.dart';

/// Re-plans local notifications whenever data or preferences change
/// (debounced) and records what was scheduled. Scheduling is not delivery:
/// history entries are labelled "scheduled".
class NotificationService {
  NotificationService(this.ref);
  final Ref ref;
  Timer? _debounce;

  void requestSync() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), _sync);
  }

  void dispose() => _debounce?.cancel();

  Future<void> _sync() async {
    final provider = ref.read(notificationProviderProvider);
    if (!provider.isSupported) return;
    final settings = ref.read(notificationSettingsProvider);
    try {
      if (!settings.masterEnabled) {
        await provider.cancelAll();
        return;
      }
      if (await provider.permissionStatus() != NotificationPermission.granted) return;
      final clock = ref.read(clockProvider);
      final now = clock.now().microsecondsSinceEpoch;
      final calendar = ref.read(financialCalendarProvider);
      final snap = ref.read(snapshotProvider);
      final today = calendar.dateOf(now);
      final earned = ref.read(earningsCalculatorProvider).liveTotal(
            snap,
            DateRange.month(today.yearMonth),
            now,
            currencyCode: ref.read(currencyProvider).code,
          );
      final planned = NotificationPlanner(calendar).plan(
        snapshot: snap,
        payments: ref.read(expectedPaymentsProvider),
        events: ref.read(calendarEventsProvider).value ?? const <CalendarEvent>[],
        settings: settings,
        backup: ref.read(backupStateProvider),
        nowMicros: now,
        money: ref.read(moneyFormatterProvider),
        privacyMode: ref.read(securitySettingsProvider).privacyMode,
        monthEndOffsetDays: ref.read(calculationSettingsProvider).monthEndReminderDay,
        earnedThisMonth: ref.read(moneyFormatterProvider).fraction(earned),
      );
      await provider.replaceAll(planned);
      await _recordHistory(planned, clock.now());
    } on Object {
      // Scheduling failures must never affect the app; they are retried on the next change.
    }
  }

  Future<void> _recordHistory(List<PlannedNotification> planned, DateTime now) async {
    final db = ref.read(databaseProvider);
    await db.batch((b) {
      for (final n in planned) {
        b.insert(
          db.notificationHistory,
          NotificationHistoryRow(
            key: n.key,
            category: n.category.name,
            title: n.title,
            scheduledFor: n.atMicros,
            createdAt: ts(now),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService(ref);
  ref.onDispose(service.dispose);
  return service;
});

/// Watches everything that influences reminders.
final notificationSyncProvider = Provider<void>((ref) {
  final service = ref.watch(notificationServiceProvider);
  ref.listen(snapshotProvider, (_, _) => service.requestSync());
  ref.listen<NotificationSettings>(notificationSettingsProvider, (_, _) => service.requestSync());
  ref.listen(calendarEventsProvider, (_, _) => service.requestSync());
  ref.listen(backupStateProvider, (_, _) => service.requestSync());
  ref.listen(securitySettingsProvider, (_, _) => service.requestSync());
  ref.listen(todayProvider, (_, _) => service.requestSync());
  service.requestSync();
});
