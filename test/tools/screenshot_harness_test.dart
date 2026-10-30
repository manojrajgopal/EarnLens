// Renders key screens with real fonts at several device sizes and system
// insets, writing PNGs to build/screens/ for visual review.
//
//   flutter test test/tools/screenshot_harness_test.dart --update-goldens --dart-define=SCREENSHOTS=true
//
// Skipped in normal test runs.
import 'dart:io';

import 'package:earnlens/app.dart';
import 'package:earnlens/core/clock.dart';
import 'package:earnlens/core/routing/app_router.dart';
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
  _Device('notch_393x852_gesture', Size(393, 852), 59, 34),
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

  for (final device in _devices) {
    testWidgets('screens ${device.name}', skip: !_enabled, (tester) async {
      await tester.runAsync(_loadFonts);
      tester.view.physicalSize = device.size * 3;
      tester.view.devicePixelRatio = 3;
      tester.view.padding = FakeViewPadding(top: device.top * 3, bottom: device.bottom * 3);
      tester.view.viewPadding = FakeViewPadding(top: device.top * 3, bottom: device.bottom * 3);
      tester.platformDispatcher.platformBrightnessTestValue = device.dark ? Brightness.dark : Brightness.light;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      final db = memoryDatabase();
      final ids = SeqIds();
      await LocalProfileRepository(db).save(UserProfile(
        displayName: 'Manoj Rajgopal',
        currencyCode: 'INR',
        locale: 'en_IN',
        timezone: 'Asia/Kolkata',
        onboardingComplete: true,
        createdAt: clock.now(),
        updatedAt: clock.now(),
      ));
      await seedAccount(db);
      await SampleDataService(LocalIncomeSourceRepository(db, clock, ids, testScope), LocalRecordsRepository(db, clock, ids, testScope), clock, ids)
          .insert(currencyCode: 'INR', today: d(2026, 10, 29));

      await tester.pumpWidget(testApp(db: db, store: InMemorySecureStore(), clock: clock));
      Future<void> settle() async {
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      await tester.runAsync(() async {
        await precacheImage(const AssetImage('assets/images/earnlens_mark.png'), tester.element(find.byType(EarnLensApp)));
      });
      await settle();
      final router = ProviderScope.containerOf(tester.element(find.byType(EarnLensApp))).read(routerProvider);
      final salary = (await db.select(db.incomeSources).get()).first.id;

      Future<void> shot(String route, String name, {double scroll = 0}) async {
        router.go(route);
        await settle();
        if (scroll > 0) {
          await tester.drag(find.byType(Scrollable).first, Offset(0, -scroll), warnIfMissed: false);
          await settle();
        }
        await expectLater(find.byType(EarnLensApp), matchesGoldenFile('../../build/screens/${device.name}/$name.png'));
      }

      await shot('/home', '01_home');
      await shot('/home', '02_home_scrolled', scroll: device.size.height * 0.8);
      await shot('/home', '03_home_scrolled_more', scroll: device.size.height * 1.6);
      await shot('/income', '04_income');
      await shot('/income/$salary', '05_source_detail');
      await shot('/calendar', '06_calendar');
      await shot('/insights', '07_insights');
      await shot('/settings', '08_settings');
      await shot('/home/reminders', '09_reminders');
      await shot('/income/new?kind=salary', '10_add_salary');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      await db.close();
    });
  }

  testWidgets('pull-to-refresh frames', skip: !_enabled, (tester) async {
    await tester.runAsync(_loadFonts);
    tester.view.physicalSize = const Size(393, 852) * 3;
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(top: 59 * 3, bottom: 34 * 3);
    addTearDown(tester.view.reset);
    final db = memoryDatabase();
    final ids = SeqIds();
    await LocalProfileRepository(db).save(UserProfile(
      displayName: 'Manoj Rajgopal',
      currencyCode: 'INR',
      locale: 'en_IN',
      timezone: 'Asia/Kolkata',
      onboardingComplete: true,
      createdAt: clock.now(),
      updatedAt: clock.now(),
    ));
    await seedAccount(db);
    await SampleDataService(LocalIncomeSourceRepository(db, clock, ids, testScope), LocalRecordsRepository(db, clock, ids, testScope), clock, ids)
        .insert(currencyCode: 'INR', today: d(2026, 10, 29));
    await tester.pumpWidget(testApp(db: db, store: InMemorySecureStore(), clock: clock));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final gesture = await tester.startGesture(const Offset(200, 300));
    for (final (i, dy) in [40.0, 80.0, 160.0].indexed) {
      await gesture.moveBy(Offset(0, dy));
      await tester.pump(const Duration(milliseconds: 16));
      await expectLater(find.byType(EarnLensApp), matchesGoldenFile('../../build/screens/refresh/0${i + 1}_pull.png'));
    }
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(find.byType(EarnLensApp), matchesGoldenFile('../../build/screens/refresh/04_refreshing.png'));
    await tester.pump(const Duration(milliseconds: 700));
    await expectLater(find.byType(EarnLensApp), matchesGoldenFile('../../build/screens/refresh/05_done.png'));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    await db.close();
  });
}
