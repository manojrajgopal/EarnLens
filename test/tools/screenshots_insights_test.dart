// Renders the calendar, insights, month history and what-if screens with real
// fonts at several device sizes, writing PNGs to build/screens/insights/ for
// visual review.
//
//   flutter test test/tools/screenshots_insights_test.dart --update-goldens --dart-define=SCREENSHOTS=true
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
  _Device('compact_320x640', Size(320, 640), 24, 48),
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
    testWidgets('insights screens ${device.name}', skip: !_enabled, (tester) async {
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

      await settle();
      final router = ProviderScope.containerOf(tester.element(find.byType(EarnLensApp))).read(routerProvider);
      final dir = '../../build/screens/insights/${device.name}';

      Future<void> snap(String name) async =>
          expectLater(find.byType(EarnLensApp), matchesGoldenFile('$dir/$name.png'));

      Future<void> shot(String route, String name, {List<double> scrolls = const []}) async {
        router.go(route);
        await settle();
        await snap(name);
        for (final (i, s) in scrolls.indexed) {
          await tester.drag(find.byType(Scrollable).first, Offset(0, -s), warnIfMissed: false);
          await settle();
          await snap('${name}_${i + 1}');
        }
      }

      final h = device.size.height * 0.75;
      await shot('/calendar', '01_calendar', scrolls: [h, h]);
      await shot('/insights', '02_insights', scrolls: [h, h, h, h, h, h]);
      await shot('/insights/month/2026-09', '03_month_history', scrolls: [h, h, h]);
      await shot('/insights/what-if', '04_what_if', scrolls: [h]);

      // Sheets.
      router.go('/insights/what-if');
      await settle();
      final add = find.text('Add a change');
      if (add.evaluate().isNotEmpty) {
        await tester.ensureVisible(add.last);
        await tester.tap(add.last, warnIfMissed: false);
        await settle();
        await snap('05_what_if_sheet');
        Navigator.of(tester.element(find.text('Preview change'))).pop();
        await settle();
      }
      router.go('/calendar');
      await settle();
      // A day with entries (1 October has an overdue payment in the sample data).
      final day1 = find.bySemanticsLabel(RegExp(r'^Thursday 1 October 2026'));
      if (day1.evaluate().isNotEmpty) {
        await tester.ensureVisible(day1.first);
        await settle();
        await tester.tap(day1.first, warnIfMissed: false);
        await settle();
        await tester.drag(find.byType(Scrollable).first, Offset(0, -h), warnIfMissed: false);
        await settle();
        await snap('01_calendar_day');
      }
      final addEvent = find.text('Add event');
      if (addEvent.evaluate().isNotEmpty) {
        await tester.ensureVisible(addEvent.first);
        await settle();
        await tester.tap(addEvent.first, warnIfMissed: false);
        await settle();
        await snap('06_event_sheet');
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      await db.close();
    });
  }
}
