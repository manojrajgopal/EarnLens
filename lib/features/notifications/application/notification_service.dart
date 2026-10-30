import 'dart:async';

import 'package:drift/drift.dart' show InsertMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/date_time/local_date.dart';
import '../../../core/formatting/money_format.dart';
import '../../../data/local/mappers.dart';
import '../../../data/repositories/local_account_repository.dart';
import '../../../data/repositories/local_earnings_data_source.dart';
import '../../../database/app_database.dart';
import '../../../domain/models/account.dart';
import '../../../domain/models/settings.dart';
import '../../../domain/money/currency.dart';
import '../domain/notification_models.dart';
import 'notification_planner.dart';

/// Re-plans local notifications whenever data or preferences change
/// (debounced) and records what was scheduled. Scheduling is not delivery:
/// history entries are labelled "scheduled".
///
/// Every active account is planned on its own: its own records, reminder
/// settings, currency and calendar. A reminder never contains another
/// account's data, and reminders of PIN-protected accounts carry no amounts,
/// source names or titles.
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
    try {
      final db = ref.read(databaseProvider);
      final settingsRepo = ref.read(settingsRepositoryProvider);
      final accounts = (await ref.read(accountRepositoryProvider).accounts()).where((a) => !a.isArchived).toList();
      final enabled = <(Account, NotificationSettings)>[];
      for (final a in accounts) {
        // Read from the database: the per-account settings streams are only
        // loaded for the account on screen.
        final json = await settingsRepo.read(accountSettingsKey(SettingsKeys.notifications, a.id));
        final settings = json == null ? const NotificationSettings() : NotificationSettings.fromJson(json);
        if (settings.masterEnabled) enabled.add((a, settings));
      }
      if (enabled.isEmpty) {
        await provider.cancelAll();
        return;
      }
      if (await provider.permissionStatus() != NotificationPermission.granted) return;
      final clock = ref.read(clockProvider);
      final now = clock.now().microsecondsSinceEpoch;
      final calendar = ref.read(financialCalendarProvider);
      final today = calendar.dateOf(now);
      final profileLocale = ref.read(profileStreamProvider).value?.locale ?? 'en_IN';
      final globalPrivacy = ref.read(securitySettingsProvider).privacyMode;
      final planned = <PlannedNotification>[];
      for (final (i, (account, settings)) in enabled.indexed) {
        final snap = await LocalEarningsDataSource(db, {account.id}).loadSnapshot();
        final events = await (db.select(db.calendarEvents)..where((t) => t.accountId.equals(account.id))).get();
        final calcJson = await settingsRepo.read(accountSettingsKey(SettingsKeys.calculation, account.id));
        final calc = calcJson == null ? const CalculationSettings() : CalculationSettings.fromJson(calcJson);
        final money = MoneyFormatter(account.locale ?? profileLocale, Currency.byCode(account.currencyCode));
        final earned = ref.read(earningsCalculatorProvider).liveTotal(
              snap,
              DateRange.month(today.yearMonth),
              now,
              currencyCode: account.currencyCode,
            );
        final plan = NotificationPlanner(calendar).plan(
          snapshot: snap,
          payments: expectedPaymentsFor(ref.read(paymentSchedulerProvider), snap, today, account.currencyCode),
          events: events.map((e) => e.toDomain()).toList(),
          settings: settings,
          // The backup reminder is app-wide: planned once.
          backup: i == 0 ? ref.read(backupStateProvider) : null,
          nowMicros: now,
          money: money,
          privacyMode: globalPrivacy || account.requiresPin,
          monthEndOffsetDays: calc.monthEndReminderDay,
          earnedThisMonth: money.fraction(earned),
        );
        planned.addAll(plan.map((n) => forAccount(n, account, labelled: enabled.length > 1)));
      }
      await provider.replaceAll(planned);
      await _recordHistory(planned, clock.now());
    } on Object {
      // Scheduling failures must never affect the app; they are retried on the next change.
    }
  }

  /// Gives [n] an account-unique key and a route that opens [account] first.
  /// Protected accounts get a generic text so nothing private shows on the
  /// lock screen.
  static PlannedNotification forAccount(PlannedNotification n, Account account, {required bool labelled}) {
    final route = Uri.parse(n.route);
    final scoped = route.replace(queryParameters: {...route.queryParameters, 'account': account.id}).toString();
    final backup = n.category == NotificationCategory.backupReminder;
    if (account.requiresPin && !backup) {
      return PlannedNotification(
        key: '${account.id}|${n.key}',
        category: n.category,
        title: 'EarnLens reminder',
        body: 'You have a reminder in a protected account. Unlock it in EarnLens to see the details.',
        atMicros: n.atMicros,
        route: scoped,
      );
    }
    return PlannedNotification(
      key: backup ? n.key : '${account.id}|${n.key}',
      category: n.category,
      title: labelled && !backup ? '${n.title} · ${account.name}' : n.title,
      body: n.body,
      atMicros: n.atMicros,
      route: backup ? n.route : scoped,
    );
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
  ref.listen(accountsProvider, (_, _) => service.requestSync());
  ref.listen(calendarEventsProvider, (_, _) => service.requestSync());
  ref.listen(backupStateProvider, (_, _) => service.requestSync());
  ref.listen(securitySettingsProvider, (_, _) => service.requestSync());
  ref.listen(todayProvider, (_, _) => service.requestSync());
  service.requestSync();
});
