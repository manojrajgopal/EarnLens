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
import '../data/repositories/local_profile_settings_repository.dart';
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

  var version = '0.1.0';
  try {
    final info = await PackageInfo.fromPlatform();
    version = '${info.version}+${info.buildNumber}';
  } on Object {
    // Version is informational only.
  }

  final db = openAppDatabase();
  final hasPin = await PinService(const PlatformSecureStore(), const SystemClock()).hasPin();

  final security = await LocalSettingsRepository(db, const SystemClock()).read('security');
  if (security != null && SecuritySettings.fromJson(security).privacyMode) {
    await PrivacyChannel.setSecure(true);
  }

  ProviderContainer? container;
  final notifications = LocalNotificationProvider(onTap: (route) => container?.read(routerProvider).go(route));

  container = ProviderContainer(overrides: [
    databaseProvider.overrideWithValue(db),
    deviceTimezoneProvider.overrideWithValue(deviceZone),
    appVersionProvider.overrideWithValue(version),
    hasPinAtLaunchProvider.overrideWithValue(hasPin),
    notificationProviderProvider.overrideWithValue(notifications),
  ]);

  // Opened from a notification while the app was not running.
  notifications.launchRoute().then((route) {
    if (route != null && route.startsWith('/')) container?.read(routerProvider).go(route);
  }).catchError((Object _) {});

  return container;
}
