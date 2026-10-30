import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../core/clock.dart';
import '../core/date_time/local_date.dart';
import '../core/errors/app_exception.dart';
import '../core/formatting/money_format.dart';
import '../core/platform/file_service.dart';
import '../core/security/biometric_service.dart';
import '../core/security/pin_service.dart';
import '../core/security/secure_store.dart';
import '../data/backup/backup_service.dart';
import '../data/backup/csv_service.dart';
import '../data/repositories/local_account_repository.dart';
import '../data/repositories/local_earnings_data_source.dart';
import '../data/repositories/local_income_source_repository.dart';
import '../data/repositories/local_profile_settings_repository.dart';
import '../data/repositories/local_records_repository.dart';
import '../database/app_database.dart';
import '../domain/calculation/accrual_engine.dart';
import '../domain/calculation/earnings_calculator.dart';
import '../domain/calculation/earnings_snapshot.dart';
import '../domain/calculation/financial_calendar.dart';
import '../domain/calculation/forecast_calculator.dart';
import '../domain/calculation/payment_schedule.dart';
import '../domain/models/account.dart';
import '../domain/models/income_source.dart';
import '../domain/models/profile.dart';
import '../domain/models/records.dart';
import '../domain/models/settings.dart';
import '../domain/money/currency.dart';
import '../domain/repositories/repositories.dart';
import '../domain/services/sample_data_service.dart';
import '../features/notifications/data/local_notification_provider.dart';
import '../features/notifications/domain/notification_models.dart';
import '../features/widgets/home_widget_bridge.dart';

// ---- Infrastructure (overridden in bootstrap and tests) --------------------

final databaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError('Database not initialised'));
final deviceTimezoneProvider = Provider<String>((ref) => 'Asia/Kolkata');
/// Full version with build number (e.g. `2.0.1+2`), recorded in backups.
final appVersionProvider = Provider<String>((ref) => '2.0.1');

/// The version as shown to people: `v2.0.1`.
final displayVersionProvider = Provider<String>((ref) => 'v${ref.watch(appVersionProvider).split('+').first}');

final clockProvider = Provider<Clock>((ref) => const SystemClock());
final idProvider = Provider<IdGenerator>((ref) => const UuidGenerator());
final secureStoreProvider = Provider<SecureStore>((ref) => const PlatformSecureStore());
final biometricServiceProvider = Provider<BiometricService>((ref) => PlatformBiometricService());
final fileServiceProvider = Provider<FileService>((ref) => const PlatformFileService());
final homeWidgetBridgeProvider = Provider<HomeWidgetBridge>((ref) => createHomeWidgetBridge());
final notificationProviderProvider = Provider<NotificationProvider>((ref) => LocalNotificationProvider());

// ---- Repositories ------------------------------------------------------------

final profileRepositoryProvider =
    Provider<ProfileRepository>((ref) => LocalProfileRepository(ref.watch(databaseProvider)));
final settingsRepositoryProvider = Provider<SettingsRepository>(
    (ref) => LocalSettingsRepository(ref.watch(databaseProvider), ref.watch(clockProvider)));
final accountRepositoryProvider = Provider<AccountRepository>((ref) =>
    LocalAccountRepository(ref.watch(databaseProvider), ref.watch(clockProvider), ref.watch(idProvider)));
final combinedAccountRepositoryProvider = Provider<CombinedAccountRepository>((ref) =>
    LocalCombinedAccountRepository(ref.watch(databaseProvider), ref.watch(clockProvider), ref.watch(idProvider)));

/// Income sources of the active view. Rebuilt whenever the view changes, so a
/// repository can only ever see and change the account on screen.
final incomeRepositoryProvider = Provider<IncomeSourceRepository>((ref) => LocalIncomeSourceRepository(
      ref.watch(databaseProvider),
      ref.watch(clockProvider),
      ref.watch(idProvider),
      ref.watch(accountScopeProvider),
    ));
final recordsRepositoryProvider = Provider<RecordsRepository>((ref) => LocalRecordsRepository(
      ref.watch(databaseProvider),
      ref.watch(clockProvider),
      ref.watch(idProvider),
      ref.watch(accountScopeProvider),
    ));
/// Repositories bound to one specific account, for flows that write to an
/// account that is not (yet) on screen: onboarding, imports, sample data.
final accountIncomeRepositoryProvider = Provider.family<IncomeSourceRepository, String>((ref, accountId) =>
    LocalIncomeSourceRepository(
        ref.watch(databaseProvider), ref.watch(clockProvider), ref.watch(idProvider), AccountScope.single(accountId)));
final accountRecordsRepositoryProvider = Provider.family<RecordsRepository, String>((ref, accountId) =>
    LocalRecordsRepository(
        ref.watch(databaseProvider), ref.watch(clockProvider), ref.watch(idProvider), AccountScope.single(accountId)));
final earningsDataSourceProvider = Provider<EarningsDataSource>(
    (ref) => LocalEarningsDataSource(ref.watch(databaseProvider), ref.watch(accountScopeProvider).visibleAccountIds));

final pinServiceProvider =
    Provider<PinService>((ref) => PinService(ref.watch(secureStoreProvider), ref.watch(clockProvider)));
final backupServiceProvider = Provider<BackupService>((ref) => BackupService(
      ref.watch(databaseProvider),
      ref.watch(clockProvider),
      appVersion: ref.watch(appVersionProvider),
    ));
final csvServiceProvider = Provider<CsvService>((ref) => CsvService(ref.watch(clockProvider), ref.watch(idProvider)));
final sampleDataServiceProvider = Provider<SampleDataService>((ref) => SampleDataService(
      ref.watch(incomeRepositoryProvider),
      ref.watch(recordsRepositoryProvider),
      ref.watch(clockProvider),
      ref.watch(idProvider),
    ));
final accountSampleDataServiceProvider = Provider.family<SampleDataService, String>((ref, accountId) =>
    SampleDataService(
      ref.watch(accountIncomeRepositoryProvider(accountId)),
      ref.watch(accountRecordsRepositoryProvider(accountId)),
      ref.watch(clockProvider),
      ref.watch(idProvider),
    ));

// ---- Accounts ------------------------------------------------------------------

final accountsStreamProvider =
    StreamProvider<List<Account>>((ref) => ref.watch(accountRepositoryProvider).watchAccounts());
final combinedAccountsStreamProvider =
    StreamProvider<List<CombinedAccount>>((ref) => ref.watch(combinedAccountRepositoryProvider).watchCombined());

/// All individual accounts (archived included), in switcher order.
final accountsProvider = Provider<List<Account>>((ref) => ref.watch(accountsStreamProvider).value ?? const []);
final combinedAccountsProvider =
    Provider<List<CombinedAccount>>((ref) => ref.watch(combinedAccountsStreamProvider).value ?? const []);

final accountByIdProvider = Provider.family<Account?, String>(
    (ref, id) => ref.watch(accountsProvider).firstWhereOrNull((a) => a.id == id));
final combinedByIdProvider = Provider.family<CombinedAccount?, String>(
    (ref, id) => ref.watch(combinedAccountsProvider).firstWhereOrNull((c) => c.id == id));

/// The view saved when the app was last used; read before the first frame.
final initialViewProvider = Provider<AccountView?>((ref) => null);

/// The view the user picked. Change it through `AccountSwitcher`, which
/// preloads the new data and persists the choice.
final selectedViewProvider = NotifierProvider<SelectedView, AccountView?>(SelectedView.new);

class SelectedView extends Notifier<AccountView?> {
  @override
  AccountView? build() => ref.read(initialViewProvider);

  void select(AccountView? view) => state = view;
}

/// The selected view if it still exists, else the first active account.
/// Null only while accounts load or before the first account exists.
AccountView? resolveView(AccountView? selected, List<Account> accounts, List<CombinedAccount> combined) {
  final valid = switch (selected) {
    IndividualView(:final id) => accounts.any((a) => a.id == id),
    CombinedView(:final id) => combined.any((c) => c.id == id),
    null => false,
  };
  if (valid) return selected;
  final first = accounts.firstWhereOrNull((a) => !a.isArchived) ?? accounts.firstOrNull;
  return first == null ? null : IndividualView(first.id);
}

final activeViewProvider = Provider<AccountView?>((ref) {
  final accounts = ref.watch(accountsStreamProvider).value;
  final combined = ref.watch(combinedAccountsStreamProvider).value;
  if (accounts == null || combined == null) return null;
  return resolveView(ref.watch(selectedViewProvider), accounts, combined);
});

/// The individual account on screen, or null in a combined view.
final activeAccountProvider = Provider<Account?>((ref) => switch (ref.watch(activeViewProvider)) {
      IndividualView(:final id) => ref.watch(accountByIdProvider(id)),
      _ => null,
    });

/// The combined account on screen, or null in an individual view.
final activeCombinedProvider = Provider<CombinedAccount?>((ref) => switch (ref.watch(activeViewProvider)) {
      CombinedView(:final id) => ref.watch(combinedByIdProvider(id)),
      _ => null,
    });

/// Combined accounts are read-only: edit actions are hidden and repositories
/// refuse writes.
final isReadOnlyViewProvider = Provider<bool>((ref) => ref.watch(activeViewProvider)?.isCombined ?? false);

/// Individual account ids the active view reads from.
final viewAccountIdsProvider = Provider<Set<String>>((ref) => switch (ref.watch(activeViewProvider)) {
      IndividualView(:final id) => {id},
      CombinedView(:final id) => {...?ref.watch(combinedByIdProvider(id))?.memberIds},
      null => const {},
    });

/// Accounts opened with their own PIN during this unlocked session.
final accountUnlocksProvider = NotifierProvider<AccountUnlocks, Set<String>>(AccountUnlocks.new);

class AccountUnlocks extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void unlock(Iterable<String> ids) => state = {...state, ...ids};

  /// Called when the app locks: protected accounts need their PIN again.
  void clear() => state = const {};
}

/// PIN-protected accounts of the active view that are not unlocked yet.
final lockedViewAccountsProvider = Provider<List<Account>>((ref) {
  final unlocked = ref.watch(accountUnlocksProvider);
  return [
    for (final id in ref.watch(viewAccountIdsProvider))
      if (ref.watch(accountByIdProvider(id)) case final a? when a.requiresPin && !unlocked.contains(id)) a,
  ];
});

/// What repositories and the snapshot may read and write. Empty while the
/// view is loading or still locked, so protected data is never even loaded.
final accountScopeProvider = Provider<AccountScope>((ref) {
  final view = ref.watch(activeViewProvider);
  if (view == null || ref.watch(lockedViewAccountsProvider).isNotEmpty) return AccountScope.none;
  final ids = ref.watch(viewAccountIdsProvider);
  return view is IndividualView ? AccountScope.single(view.id) : AccountScope.readOnly(ids);
});

// ---- Profile & settings ------------------------------------------------------

final profileStreamProvider = StreamProvider<UserProfile?>((ref) => ref.watch(profileRepositoryProvider).watch());

final _settingsStreams = <String, StreamProvider<Map<String, dynamic>?>>{};
StreamProvider<Map<String, dynamic>?> _settingsKey(String key) => _settingsStreams.putIfAbsent(
      key,
      () => StreamProvider<Map<String, dynamic>?>((ref) => ref.watch(settingsRepositoryProvider).watch(key)),
    );

abstract final class SettingsKeys {
  // Per view: `dashboard@<accountId>` or `dashboard@combined:<id>`.
  static const dashboard = 'dashboard';
  static const appearance = 'appearance';
  static const security = 'security';
  // Per individual account: `notifications@<accountId>`, `calculation@<accountId>`.
  static const notifications = 'notifications';
  static const calculation = 'calculation';
  static const backup = 'backup';
  static const activeView = 'activeView';
}

/// Dashboard layout and visible rates of the active view.
final dashboardConfigProvider = Provider<DashboardConfig>((ref) {
  final view = ref.watch(activeViewProvider);
  if (view == null) return DashboardConfig.defaults();
  final m = ref.watch(_settingsKey(accountSettingsKey(SettingsKeys.dashboard, view.settingsKey))).value;
  return m == null ? DashboardConfig.defaults() : DashboardConfig.fromJson(m);
});
final appearanceProvider = Provider<AppearanceSettings>((ref) {
  final m = ref.watch(_settingsKey(SettingsKeys.appearance)).value;
  return m == null ? const AppearanceSettings() : AppearanceSettings.fromJson(m);
});
final securitySettingsProvider = Provider<SecuritySettings>((ref) {
  final m = ref.watch(_settingsKey(SettingsKeys.security)).value;
  return m == null ? const SecuritySettings() : SecuritySettings.fromJson(m);
});
/// Reminder preferences of one individual account.
final accountNotificationSettingsProvider = Provider.family<NotificationSettings, String>((ref, accountId) {
  final m = ref.watch(_settingsKey(accountSettingsKey(SettingsKeys.notifications, accountId))).value;
  return m == null ? const NotificationSettings() : NotificationSettings.fromJson(m);
});

/// Defaults for new income sources of one individual account.
final accountCalculationSettingsProvider = Provider.family<CalculationSettings, String>((ref, accountId) {
  final m = ref.watch(_settingsKey(accountSettingsKey(SettingsKeys.calculation, accountId))).value;
  return m == null ? const CalculationSettings() : CalculationSettings.fromJson(m);
});

/// Reminder preferences of the active account (defaults in combined views,
/// whose settings are read-only).
final notificationSettingsProvider = Provider<NotificationSettings>((ref) {
  final id = ref.watch(activeAccountProvider)?.id;
  return id == null ? const NotificationSettings() : ref.watch(accountNotificationSettingsProvider(id));
});
final calculationSettingsProvider = Provider<CalculationSettings>((ref) {
  final id = ref.watch(activeAccountProvider)?.id;
  return id == null ? const CalculationSettings() : ref.watch(accountCalculationSettingsProvider(id));
});
final backupStateProvider = Provider<BackupState>((ref) {
  final m = ref.watch(_settingsKey(SettingsKeys.backup)).value;
  return m == null ? const BackupState() : BackupState.fromJson(m);
});

/// Writes typed settings sections. Dashboard, notification and calculation
/// settings belong to the active view and are never shared between accounts.
class SettingsController {
  SettingsController(this._repo, this._view);
  final SettingsRepository _repo;
  final AccountView? _view;

  /// Per-account sections can only be changed in an individual view.
  String _accountKey(String section) => switch (_view) {
        IndividualView(:final id) => accountSettingsKey(section, id),
        _ => throw const ReadOnlyViewException(),
      };

  Future<void> saveDashboard(DashboardConfig c) {
    final view = _view;
    if (view == null) throw const ReadOnlyViewException();
    return _repo.write(accountSettingsKey(SettingsKeys.dashboard, view.settingsKey), c.toJson());
  }

  Future<void> saveAppearance(AppearanceSettings s) => _repo.write(SettingsKeys.appearance, s.toJson());
  Future<void> saveSecurity(SecuritySettings s) => _repo.write(SettingsKeys.security, s.toJson());
  Future<void> saveNotifications(NotificationSettings s) =>
      _repo.write(_accountKey(SettingsKeys.notifications), s.toJson());
  Future<void> saveCalculation(CalculationSettings s) => _repo.write(_accountKey(SettingsKeys.calculation), s.toJson());
  Future<void> saveBackup(BackupState s) => _repo.write(SettingsKeys.backup, s.toJson());
}

/// Settings of one specific individual account.
final accountSettingsControllerProvider = Provider.family<SettingsController, String>(
    (ref, accountId) => SettingsController(ref.watch(settingsRepositoryProvider), IndividualView(accountId)));

final settingsControllerProvider = Provider<SettingsController>(
    (ref) => SettingsController(ref.watch(settingsRepositoryProvider), ref.watch(activeViewProvider)));

// ---- Calculation -------------------------------------------------------------

final financialCalendarProvider = Provider<FinancialCalendar>((ref) {
  final String? profileZone = ref.watch(profileStreamProvider).value?.timezone;
  final String name = profileZone ?? ref.watch(deviceTimezoneProvider);
  tz.Location location;
  try {
    location = tz.getLocation(name);
  } on Object {
    location = tz.UTC;
  }
  return FinancialCalendar(location);
});

final accrualEngineProvider = Provider<AccrualEngine>((ref) => AccrualEngine(ref.watch(financialCalendarProvider)));
final earningsCalculatorProvider =
    Provider<EarningsCalculator>((ref) => EarningsCalculator(ref.watch(accrualEngineProvider)));
final forecastCalculatorProvider =
    Provider<ForecastCalculator>((ref) => ForecastCalculator(ref.watch(earningsCalculatorProvider)));
final paymentSchedulerProvider =
    Provider<PaymentScheduler>((ref) => PaymentScheduler(ref.watch(accrualEngineProvider)));

/// Live snapshot of one scope. Each view has its own instance, so a newly
/// opened account starts from its own data, never from the previous
/// account's figures. Disposed when no longer shown.
final scopedSnapshotProvider = StreamProvider.autoDispose.family<EarningsSnapshot, AccountScope>(
    (ref, scope) => LocalEarningsDataSource(ref.watch(databaseProvider), scope.visibleAccountIds).watchSnapshot());

/// Snapshot of the active view: loading until its scope is known and loaded.
final snapshotStreamProvider = Provider<AsyncValue<EarningsSnapshot>>((ref) {
  final scope = ref.watch(accountScopeProvider);
  if (scope.visibleAccountIds.isEmpty) {
    final accounts = ref.watch(accountsStreamProvider).value;
    // No account yet (first launch): nothing to show rather than a spinner.
    return accounts != null && accounts.isEmpty ? AsyncData(EarningsSnapshot.empty) : const AsyncLoading();
  }
  return ref.watch(scopedSnapshotProvider(scope));
});

/// Latest snapshot, empty while loading.
final snapshotProvider = Provider<EarningsSnapshot>((ref) => ref.watch(snapshotStreamProvider).value ?? EarningsSnapshot.empty);

/// Display currency of the active view: the account's currency, or the
/// combined account's chosen currency. Amounts in other currencies are never
/// converted or added in.
final currencyProvider = Provider<Currency>((ref) {
  final code = ref.watch(activeAccountProvider)?.currencyCode ??
      ref.watch(activeCombinedProvider)?.currencyCode ??
      ref.watch(profileStreamProvider).value?.currencyCode ??
      Currency.inr.code;
  return Currency.byCode(code);
});

/// Number formatting locale: the account's override, else the profile's.
final localeProvider = Provider<String>((ref) =>
    ref.watch(activeAccountProvider)?.locale ?? ref.watch(profileStreamProvider).value?.locale ?? 'en_IN');

final moneyFormatterProvider =
    Provider<MoneyFormatter>((ref) => MoneyFormatter(ref.watch(localeProvider), ref.watch(currencyProvider)));

MoneyFormatter formatterFor(Ref ref, String currencyCode) =>
    MoneyFormatter(ref.watch(localeProvider), Currency.byCode(currencyCode));

/// Emits once per second for live counters. Only active while watched.
final tickerProvider = StreamProvider<DateTime>((ref) {
  final clock = ref.watch(clockProvider);
  return Stream<DateTime>.periodic(const Duration(seconds: 1), (_) => clock.now());
});

/// "Now" for live figures. Advances with [tickerProvider] every second and
/// pauses with it when nothing visible is listening. Earnings computed from it
/// are recalculated from the pay rules on each tick (never incremented), so
/// they stay exact after suspension or restart.
final liveNowProvider = Provider<DateTime>((ref) {
  final clock = ref.watch(clockProvider);
  return ref.watch(tickerProvider).value ?? clock.now();
});

/// Ticks every minute so date-dependent values roll over at midnight.
final minuteTickerProvider = StreamProvider<int>((ref) =>
    Stream<int>.periodic(const Duration(minutes: 1), (i) => i));

/// Today's date in the financial timezone. Dependents only rebuild when the
/// date actually changes.
final todayProvider = Provider<LocalDate>((ref) {
  ref.watch(minuteTickerProvider);
  final cal = ref.watch(financialCalendarProvider);
  return cal.today(ref.watch(clockProvider).now());
});

final sourcesProvider = Provider<List<IncomeSource>>((ref) => ref.watch(snapshotProvider).sources);

final sourceProvider = Provider.family<IncomeSource?, String>((ref, id) => ref.watch(snapshotProvider).source(id));

final revisionsProvider = StreamProvider.family<List<RateRevision>, String>(
    (ref, id) => ref.watch(incomeRepositoryProvider).watchRevisions(id));

final pausesProvider = StreamProvider.family<List<SourcePause>, String>(
    (ref, id) => ref.watch(incomeRepositoryProvider).watchPauses(id));

final overridesProvider = StreamProvider<List<DayOverride>>((ref) => ref.watch(incomeRepositoryProvider).watchOverrides());

final calendarEventsProvider =
    StreamProvider<List<CalendarEvent>>((ref) => ref.watch(recordsRepositoryProvider).watchEvents());

final auditProvider = StreamProvider.family<List<AuditEntry>, String?>(
    (ref, entityId) => ref.watch(recordsRepositoryProvider).watchAudit(entityId: entityId));

/// Expected payments in [currency] from four months back to three months
/// ahead.
List<ExpectedPayment> expectedPaymentsFor(
  PaymentScheduler scheduler,
  EarningsSnapshot snap,
  LocalDate today,
  String currency,
) {
  final rules = [
    for (final r in snap.rules.values)
      if (r.source.currencyCode == currency) r,
  ];
  return scheduler.expectedPayments(
    rules: rules,
    items: snap.items.where((i) => i.currencyCode == currency).toList(),
    ledger: snap.ledger,
    periods: [for (var i = -4; i <= 3; i++) today.yearMonth.addMonths(i)],
    today: today,
  );
}

/// Expected payments of the active view.
final expectedPaymentsProvider = Provider<List<ExpectedPayment>>((ref) => expectedPaymentsFor(
      ref.watch(paymentSchedulerProvider),
      ref.watch(snapshotProvider),
      ref.watch(todayProvider),
      ref.watch(currencyProvider).code,
    ));
