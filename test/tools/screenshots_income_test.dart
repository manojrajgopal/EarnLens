// Renders key screens with real fonts at several device sizes and system
// insets, writing PNGs to build/screens/ for visual review.
//
//   flutter test test/tools/screenshots_income_test.dart --update-goldens --dart-define=SCREENSHOTS=true
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
  _Device('punch_412x915_gesture_dark', Size(412, 915), 36, 24, dark: true),
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
      final all = await db.select(db.incomeSources).get();
      final salary = all.first.id;
      final variable = all.firstWhere((s) => s.name.contains('Freelance')).id;

      Future<void> shot(String route, String name, {double scroll = 0}) async {
        router.go(route);
        await settle();
        if (scroll > 0) {
          await tester.drag(find.byType(Scrollable).first, Offset(0, -scroll), warnIfMissed: false);
          await settle();
        }
        await expectLater(find.byType(EarnLensApp), matchesGoldenFile('../../build/screens/income/${device.name}/$name.png'));
      }

      final h = device.size.height;
      await shot('/income', '01_income');
      await shot('/income', '02_income_scrolled', scroll: h * 0.6);
      await tester.tap(find.text('Add income').last);
      await settle();
      await expectLater(find.byType(EarnLensApp), matchesGoldenFile('../../build/screens/income/${device.name}/03_add_sheet.png'));
      Navigator.of(tester.element(find.text('What kind of income?')), rootNavigator: true).pop();
      await settle();
      await shot('/income/$salary', '04_detail');
      await shot('/income/$salary', '05_detail_s1', scroll: h * 0.7);
      await shot('/income/$salary', '06_detail_s2', scroll: h * 0.7);
      await shot('/income/$salary', '07_detail_s3', scroll: h * 0.7);
      await shot('/income/$salary', '08_detail_s4', scroll: h * 0.7);
      await shot('/income/$salary', '08b_detail_s5', scroll: h * 0.7);
      await shot('/income/$variable', '09_detail_variable');
      await shot('/income/$variable', '09b_detail_variable_s', scroll: h * 0.8);
      await shot('/income/new?kind=salary', '10_add_salary');
      await shot('/income/new?kind=salary', '11_add_salary_s1', scroll: h * 0.7);
      await shot('/income/new?kind=salary', '12_add_salary_s2', scroll: h * 0.7);
      await shot('/income/new?kind=salary', '12b_add_salary_s3', scroll: h * 0.7);
      await shot('/income/new?kind=temporary', '13_add_temporary', scroll: h * 0.7);
      await shot('/income/$salary/edit', '14_edit_salary');
      await shot('/income/$salary/revision', '15_revision');
      await shot('/income/$salary/revision', '16_revision_s', scroll: h * 0.7);
      await shot('/income/$salary/item', '17_item');
      await shot('/income/$salary/item', '18_item_s', scroll: h * 0.7);
      await shot('/income/$salary/entry?type=received', '19_entry');
      await shot('/income/$salary/entry?type=received', '20_entry_s', scroll: h * 0.7);
      await shot('/income/$variable/month/2026-10', '21_month');
      await shot('/income/$variable/month/2026-10', '22_month_s1', scroll: h * 0.7);
      await shot('/income/$variable/month/2026-10', '23_month_s2', scroll: h * 0.7);
      await shot('/settings/holidays', '24_holidays');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      await db.close();
    });
  }
}
