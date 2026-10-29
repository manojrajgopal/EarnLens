// Renders the dashboard at the reference design's viewport (412 dp wide,
// 2x) for side-by-side comparison, plus a tall full-page capture so the whole
// dashboard can be compared against the reference poster in one image.
//
//   flutter test test/tools/reference_compare_test.dart --update-goldens --dart-define=SCREENSHOTS=true
//
// Writes PNGs to build/screens/reference/. Skipped in normal test runs.
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

  for (final (name, height, routes) in [
    ('viewport_412x952', 952.0, const ['/home']),
    ('fullpage_412x2000', 2000.0, const ['/home']),
    (
      'screens_412x915',
      915.0,
      const [
        '/income',
        '/income/{salary}',
        '/calendar',
        '/insights',
        '/settings',
        '/home/reminders',
        '/income/new?kind=salary',
        '/home/search',
        '/settings/data',
      ]
    ),
  ]) {
    testWidgets('reference $name', skip: !_enabled, (tester) async {
      await tester.runAsync(_loadFonts);
      tester.view.physicalSize = Size(412, height) * 2;
      tester.view.devicePixelRatio = 2;
      tester.view.padding = const FakeViewPadding(top: 36 * 2, bottom: 24 * 2);
      tester.view.viewPadding = const FakeViewPadding(top: 36 * 2, bottom: 24 * 2);
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
      await SampleDataService(LocalIncomeSourceRepository(db, clock, ids), LocalRecordsRepository(db, clock, ids), clock, ids)
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

      for (final (i, r) in routes.indexed) {
        router.go(r.replaceAll('{salary}', salary));
        await settle();
        final file = routes.length == 1 ? name : '${name}_${(i + 1).toString().padLeft(2, '0')}';
        await expectLater(find.byType(EarnLensApp), matchesGoldenFile('../../build/screens/reference/$file.png'));
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      await db.close();
    });
  }
}
