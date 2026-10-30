import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/clock.dart';
import '../core/platform/privacy_channel.dart';
import '../core/routing/app_router.dart';
import '../core/security/pin_service.dart';
import '../core/security/secure_store.dart';
import '../data/repositories/local_account_repository.dart';
import '../data/repositories/local_profile_settings_repository.dart';
import '../database/app_database.dart';
import '../domain/models/account.dart';
import '../features/accounts/application/account_controller.dart';
import '../database/database_factory.dart';
import '../domain/models/settings.dart';
import '../features/authentication/application/session_controller.dart';
import '../features/notifications/data/local_notification_provider.dart';
import 'dependency_injection.dart';

/// Everything that must happen before the first frame. Returns the root
/// [ProviderContainer] with platform services wired in.
Future<ProviderContainer> initializeApp() async {
  // Edge-to-edge: backgrounds may draw behind the status/navigation bars;
  // interactive content respects MediaQuery insets (see AppInsets).
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  tzdata.initializeTimeZones();
  await initializeDateFormatting();
  LicenseRegistry.addLicense(() async* {
    final ofl = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Urbanist font'], ofl);
  });

  var deviceZone = 'Asia/Kolkata';
  try {
    final info = await FlutterTimezone.getLocalTimezone();
    tz.getLocation(info.identifier);
    deviceZone = info.identifier;
  } on Object {
    // Unknown zone name: fall back to the Indian-market default.
  }

  var version = '2.0.1';
  try {
    final info = await PackageInfo.fromPlatform();
    version = '${info.version}+${info.buildNumber}';
  } on Object {
    // Version is informational only.
  }

  final db = openAppDatabase();
  final hasPin = await PinService(const PlatformSecureStore(), const SystemClock()).hasPin();

  final settings = LocalSettingsRepository(db, const SystemClock());
  final security = await settings.read(SettingsKeys.security);
  // Restore the last opened account before the first frame, so the app never
  // shows another account's figures while starting.
  final initialView = AccountView.fromJson(await settings.read(SettingsKeys.activeView));
  await _ensureAccount(db);
  if (security != null && SecuritySettings.fromJson(security).privacyMode) {
    await PrivacyChannel.setSecure(true);
  }

  ProviderContainer? container;
  void openRoute(String route) {
    final c = container;
    if (c == null) return;
    c.read(accountControllerProvider).openRoute(route, c.read(routerProvider).go);
  }

  final notifications = LocalNotificationProvider(onTap: openRoute);

  container = ProviderContainer(overrides: [
    databaseProvider.overrideWithValue(db),
    deviceTimezoneProvider.overrideWithValue(deviceZone),
    appVersionProvider.overrideWithValue(version),
    hasPinAtLaunchProvider.overrideWithValue(hasPin),
    notificationProviderProvider.overrideWithValue(notifications),
    initialViewProvider.overrideWithValue(initialView),
  ]);

  // Opened from a notification while the app was not running.
  notifications.launchRoute().then((route) {
    if (route != null && route.startsWith('/')) openRoute(route);
  }).catchError((Object _) {});

  return container;
}

/// Every onboarded install has at least one account (the v2 migration and
/// onboarding create it); this repairs a database restored from an unusual
/// state, so records always have an account to be shown in.
Future<void> _ensureAccount(AppDatabase db) async {
  final profile = await db.select(db.profiles).getSingleOrNull();
  if (profile == null || !profile.onboardingComplete) return;
  if ((await db.select(db.accounts).get()).isNotEmpty) return;
  final now = DateTime.now();
  await LocalAccountRepository(db, const SystemClock(), const UuidGenerator()).createAccount(Account(
    id: const UuidGenerator().newId(),
    name: AccountType.personal.label,
    type: AccountType.personal,
    currencyCode: profile.currencyCode,
    createdAt: now,
    updatedAt: now,
  ));
}
