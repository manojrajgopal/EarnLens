// Renders the settings, data, history, help/about, onboarding and PIN screens
// with real fonts at several device sizes, writing PNGs to
// build/screens/settings/ for visual review.
//
//   flutter test test/tools/screenshots_settings_test.dart --update-goldens --dart-define=SCREENSHOTS=true
//
// Skipped in normal test runs.
import 'dart:io';

import 'package:earnlens/app.dart';
import 'package:earnlens/core/clock.dart';
import 'package:earnlens/core/routing/app_router.dart';
import 'package:earnlens/core/security/pin_service.dart';
import 'package:earnlens/core/security/secure_store.dart';
import 'package:earnlens/data/repositories/local_income_source_repository.dart';
import 'package:earnlens/data/repositories/local_profile_settings_repository.dart';
import 'package:earnlens/data/repositories/local_records_repository.dart';
import 'package:earnlens/domain/models/profile.dart';
import 'package:earnlens/domain/services/sample_data_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_app.dart';
import '../helpers/test_database.dart';

const _enabled = bool.fromEnvironment('SCREENSHOTS');

class _Device {
  const _Device(this.name, this.size, this.top, this.bottom, {this.dark = false});
  final String name;
  final Size size;
  final double top;
  final double bottom;
  final bool dark;
}

const _devices = [
  _Device('small_360x640_3button', Size(360, 640), 24, 48),
  _Device('punch_412x915_gesture_dark', Size(412, 915), 36, 24, dark: true),
  _Device('tablet_820x1180', Size(820, 1180), 24, 20),
];

Future<void> _loadFonts() async {
  final urbanist = FontLoader('Urbanist')..addFont(rootBundle.load('assets/fonts/Urbanist-Variable.ttf'));
  await urbanist.load();
  final root = Platform.environment['FLUTTER_ROOT'] ?? r'D:\flutter';
  final icons = File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.view(icons.readAsBytesSync().buffer)));
    await loader.load();
  }
}

void main() {
  final clock = FixedClock(DateTime.utc(2026, 10, 29, 4, 30)); // 10:00 IST

  Future<void> setUpDevice(WidgetTester tester, _Device device) async {
    await tester.runAsync(_loadFonts);
    tester.view.physicalSize = device.size * 3;
    tester.view.devicePixelRatio = 3;
    tester.view.padding = FakeViewPadding(top: device.top * 3, bottom: device.bottom * 3);
    tester.view.viewPadding = FakeViewPadding(top: device.top * 3, bottom: device.bottom * 3);
    tester.platformDispatcher.platformBrightnessTestValue = device.dark ? Brightness.dark : Brightness.light;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> precache(WidgetTester tester) => tester.runAsync(() async {
        await precacheImage(const AssetImage('assets/images/earnlens_mark.png'), tester.element(find.byType(EarnLensApp)));
      });

  Future<void> seedProfile(dynamic db) async {
    await LocalProfileRepository(db).save(UserProfile(
      displayName: 'Manoj Rajgopal',
      currencyCode: 'INR',
      locale: 'en_IN',
      timezone: 'Asia/Kolkata',
      onboardingComplete: true,
      createdAt: clock.now(),
      updatedAt: clock.now(),
    ));
  }

  for (final device in _devices) {
    final dir = '../../build/screens/settings/${device.name}';

    testWidgets('settings ${device.name}', skip: !_enabled, (tester) async {
      await setUpDevice(tester, device);
      final db = memoryDatabase();
      final ids = SeqIds();
      await seedProfile(db);
      await SampleDataService(LocalIncomeSourceRepository(db, clock, ids), LocalRecordsRepository(db, clock, ids), clock, ids)
          .insert(currencyCode: 'INR', today: d(2026, 10, 29));
      await tester.pumpWidget(testApp(db: db, store: InMemorySecureStore(), clock: clock));
      await precache(tester);
      await settle(tester);
      final router = ProviderScope.containerOf(tester.element(find.byType(EarnLensApp))).read(routerProvider);

      Future<void> shot(String route, String name, {double scroll = 0}) async {
        router.go(route);
        await settle(tester);
        if (scroll > 0) {
          await tester.drag(find.byType(Scrollable).hitTestable().first, Offset(0, -scroll), warnIfMissed: false);
          await settle(tester);
        }
        await expectLater(find.byType(EarnLensApp), matchesGoldenFile('$dir/$name.png'));
      }

      await shot('/settings', '01_settings');
      await shot('/settings', '02_settings_scrolled', scroll: device.size.height * 0.8);
      await shot('/settings/profile', '03_profile');
      await shot('/settings/appearance', '04_appearance');
      await shot('/settings/calculation', '05_calculation');
      await shot('/settings/security', '06_security');
      await shot('/settings/notifications', '07_notifications');
      await shot('/settings/data', '08_data');
      await shot('/settings/data', '09_data_scrolled', scroll: device.size.height * 0.8);
      await shot('/settings/audit', '10_audit');
      await shot('/settings/about', '11_about');
      await shot('/settings/privacy', '12_privacy');
      await shot('/settings/help', '13_help');
      await shot('/settings/security/change-pin', '14_set_pin');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      await db.close();
    });

    testWidgets('onboarding ${device.name}', skip: !_enabled, (tester) async {
      await setUpDevice(tester, device);
      final db = memoryDatabase();
      await tester.pumpWidget(testApp(db: db, store: InMemorySecureStore(), clock: clock));
      await precache(tester);
      await settle(tester);
      await expectLater(find.byType(EarnLensApp), matchesGoldenFile('$dir/20_welcome.png'));

      final router = ProviderScope.containerOf(tester.element(find.byType(EarnLensApp))).read(routerProvider);
      router.go('/onboarding');
      await settle(tester);
      await expectLater(find.byType(EarnLensApp), matchesGoldenFile('$dir/21_onboarding_profile.png'));

      // Keyboard open: the primary action must stay visible above it.
      tester.view.viewInsets = const FakeViewPadding(bottom: 280 * 3);
      await tester.showKeyboard(find.byType(TextFormField).first);
      await settle(tester);
      await expectLater(find.byType(EarnLensApp), matchesGoldenFile('$dir/22_onboarding_keyboard.png'));
      tester.view.resetViewInsets();
      await tester.enterText(find.byType(TextFormField).first, 'Asha');
      FocusManager.instance.primaryFocus?.unfocus();
      await settle(tester);

      Future<void> next(String label) async {
        await tester.tap(find.text(label).last);
        await settle(tester);
      }

      await next('Continue');
      await expectLater(find.byType(EarnLensApp), matchesGoldenFile('$dir/23_onboarding_units.png'));
      await next('Continue');
      await expectLater(find.byType(EarnLensApp), matchesGoldenFile('$dir/24_onboarding_income.png'));
      await tester.tap(find.byType(Switch).first);
      await settle(tester);
      await next('Skip for now');
      await expectLater(find.byType(EarnLensApp), matchesGoldenFile('$dir/25_onboarding_pin.png'));
      for (final ch in '4829'.split('')) {
        await tester.tap(find.text(ch).last);
        await tester.pump();
      }
      await tester.tap(find.text('Next'));
      await settle(tester);
      await tester.tap(find.text('1').last);
      await tester.pump();
      await expectLater(find.byType(EarnLensApp), matchesGoldenFile('$dir/26_onboarding_pin_confirm.png'));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      await db.close();
    });

    testWidgets('lock ${device.name}', skip: !_enabled, (tester) async {
      await setUpDevice(tester, device);
      final db = memoryDatabase();
      final store = InMemorySecureStore();
      await seedProfile(db);
      await PinService(store, clock, iterations: 1000, useIsolate: false).setPin('4829');
      await tester.pumpWidget(testApp(db: db, store: store, clock: clock, hasPin: true));
      await precache(tester);
      await settle(tester);
      await expectLater(find.byType(EarnLensApp), matchesGoldenFile('$dir/30_lock.png'));
      for (final ch in '1357'.split('')) {
        await tester.tap(find.text(ch).last);
        await tester.pump();
      }
      await tester.tap(find.text('Unlock'));
      await settle(tester);
      await expectLater(find.byType(EarnLensApp), matchesGoldenFile('$dir/31_lock_error.png'));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      await db.close();
    });
  }
}
