import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../core/clock.dart';
import '../core/date_time/local_date.dart';
import '../core/formatting/money_format.dart';
import '../core/platform/file_service.dart';
import '../core/security/biometric_service.dart';
import '../core/security/pin_service.dart';
import '../core/security/secure_store.dart';
import '../data/backup/backup_service.dart';
import '../data/backup/csv_service.dart';
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
final appVersionProvider = Provider<String>((ref) => '0.1.0');

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
final incomeRepositoryProvider = Provider<IncomeSourceRepository>((ref) =>
    LocalIncomeSourceRepository(ref.watch(databaseProvider), ref.watch(clockProvider), ref.watch(idProvider)));
final recordsRepositoryProvider = Provider<RecordsRepository>((ref) =>
    LocalRecordsRepository(ref.watch(databaseProvider), ref.watch(clockProvider), ref.watch(idProvider)));
final earningsDataSourceProvider =
    Provider<EarningsDataSource>((ref) => LocalEarningsDataSource(ref.watch(databaseProvider)));

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

// ---- Profile & settings ------------------------------------------------------

final profileStreamProvider = StreamProvider<UserProfile?>((ref) => ref.watch(profileRepositoryProvider).watch());

final _settingsStreams = <String, StreamProvider<Map<String, dynamic>?>>{};
StreamProvider<Map<String, dynamic>?> _settingsKey(String key) => _settingsStreams.putIfAbsent(
      key,
      () => StreamProvider<Map<String, dynamic>?>((ref) => ref.watch(settingsRepositoryProvider).watch(key)),
    );

abstract final class SettingsKeys {
  static const dashboard = 'dashboard';
  static const appearance = 'appearance';
  static const security = 'security';
  static const notifications = 'notifications';
  static const calculation = 'calculation';
  static const backup = 'backup';
}

final dashboardConfigProvider = Provider<DashboardConfig>((ref) {
  final m = ref.watch(_settingsKey(SettingsKeys.dashboard)).value;
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
final notificationSettingsProvider = Provider<NotificationSettings>((ref) {
  final m = ref.watch(_settingsKey(SettingsKeys.notifications)).value;
  return m == null ? const NotificationSettings() : NotificationSettings.fromJson(m);
});
final calculationSettingsProvider = Provider<CalculationSettings>((ref) {
  final m = ref.watch(_settingsKey(SettingsKeys.calculation)).value;
  return m == null ? const CalculationSettings() : CalculationSettings.fromJson(m);
});
final backupStateProvider = Provider<BackupState>((ref) {
  final m = ref.watch(_settingsKey(SettingsKeys.backup)).value;
  return m == null ? const BackupState() : BackupState.fromJson(m);
});

/// Writes typed settings sections.
class SettingsController {
  SettingsController(this._repo);
  final SettingsRepository _repo;

  Future<void> saveDashboard(DashboardConfig c) => _repo.write(SettingsKeys.dashboard, c.toJson());
  Future<void> saveAppearance(AppearanceSettings s) => _repo.write(SettingsKeys.appearance, s.toJson());
  Future<void> saveSecurity(SecuritySettings s) => _repo.write(SettingsKeys.security, s.toJson());
  Future<void> saveNotifications(NotificationSettings s) => _repo.write(SettingsKeys.notifications, s.toJson());
  Future<void> saveCalculation(CalculationSettings s) => _repo.write(SettingsKeys.calculation, s.toJson());
  Future<void> saveBackup(BackupState s) => _repo.write(SettingsKeys.backup, s.toJson());
}

final settingsControllerProvider =
    Provider<SettingsController>((ref) => SettingsController(ref.watch(settingsRepositoryProvider)));

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

final snapshotStreamProvider =
    StreamProvider<EarningsSnapshot>((ref) => ref.watch(earningsDataSourceProvider).watchSnapshot());

/// Latest snapshot, empty while loading.
final snapshotProvider = Provider<EarningsSnapshot>((ref) => ref.watch(snapshotStreamProvider).value ?? EarningsSnapshot.empty);

final currencyProvider = Provider<Currency>(
    (ref) => Currency.byCode(ref.watch(profileStreamProvider).value?.currencyCode ?? Currency.inr.code));

final moneyFormatterProvider = Provider<MoneyFormatter>((ref) {
  final profile = ref.watch(profileStreamProvider).value;
  return MoneyFormatter(profile?.locale ?? 'en_IN', ref.watch(currencyProvider));
});

MoneyFormatter formatterFor(Ref ref, String currencyCode) {
  final profile = ref.watch(profileStreamProvider).value;
  return MoneyFormatter(profile?.locale ?? 'en_IN', Currency.byCode(currencyCode));
}

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

/// Expected payments from three months back to three months ahead.
final expectedPaymentsProvider = Provider<List<ExpectedPayment>>((ref) {
  final snap = ref.watch(snapshotProvider);
  final today = ref.watch(todayProvider);
  final currency = ref.watch(currencyProvider).code;
  final scheduler = ref.watch(paymentSchedulerProvider);
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
});
