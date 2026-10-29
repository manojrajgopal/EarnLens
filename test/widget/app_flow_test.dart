import 'package:earnlens/core/clock.dart';
import 'package:earnlens/core/security/pin_service.dart';
import 'package:earnlens/core/security/secure_store.dart';
import 'package:earnlens/data/repositories/local_income_source_repository.dart';
import 'package:earnlens/data/repositories/local_profile_settings_repository.dart';
import 'package:earnlens/database/app_database.dart';
import 'package:earnlens/domain/calculation/rate_calculator.dart';
import 'package:earnlens/domain/models/profile.dart';
import 'package:earnlens/domain/models/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_app.dart';
import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late InMemorySecureStore store;
  final clock = FixedClock(DateTime.utc(2024, 10, 15, 6, 30));

  setUp(() {
    db = memoryDatabase();
    store = InMemorySecureStore();
  });

  /// Pumps frames without waiting for the 1 Hz ticker to "settle".
  Future<void> settle(WidgetTester tester, [int frames = 20]) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Unmounts the app and flushes Drift's stream-close timers.
  Future<void> done(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    await db.close();
  }

  /// Scrolls the nearest vertical list until [text] is visible, then taps it.
  Future<void> tapText(WidgetTester tester, String text) async {
    final f = find.text(text);
    await tester.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).hitTestable().last);
    await tester.ensureVisible(f);
    await tester.pump();
    await tester.tap(f);
  }

  Future<void> phone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Future<void> seedProfile({bool withSalary = true}) async {
    await LocalProfileRepository(db).save(UserProfile(
      displayName: 'Asha',
      currencyCode: 'INR',
      locale: 'en_IN',
      timezone: 'Asia/Kolkata',
      onboardingComplete: true,
      createdAt: clock.now(),
      updatedAt: clock.now(),
    ));
    if (withSalary) {
      final s = source(id: 'sal', start: d(2024, 1, 1));
      await LocalIncomeSourceRepository(db, clock, SeqIds())
          .createSource(s, initialRate: rev('sal', s.startDate, 3100000));
    }
  }

  Future<void> enterPin(WidgetTester tester, String pin) async {
    for (final ch in pin.split('')) {
      final key = find.text(ch).last;
      await tester.ensureVisible(key);
      await tester.tap(key);
      await tester.pump();
    }
  }

  testWidgets('first launch: onboarding → PIN → dashboard', (tester) async {
    await phone(tester);
    await tester.pumpWidget(testApp(db: db, store: store, clock: clock));
    await settle(tester);

    expect(find.textContaining('Your earnings'), findsOneWidget);
    expect(find.textContaining('stays on this device'), findsOneWidget);
    await tapText(tester, 'Get started');
    await settle(tester);

    // Step 1: name is required.
    await tapText(tester, 'Continue');
    await settle(tester, 5);
    expect(find.text('Enter a name'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Asha');
    await tapText(tester, 'Continue');
    await settle(tester);

    // Step 2: earning units — defaults kept.
    expect(find.text('Main rate'), findsOneWidget);
    await tapText(tester, 'Continue');
    await settle(tester);

    // Step 3: add salary.
    await tester.enterText(find.widgetWithText(TextFormField, 'Employer'), 'Acme');
    await tester.enterText(find.widgetWithText(TextFormField, 'Monthly gross salary'), '31000');
    await tapText(tester, 'Continue');
    await settle(tester);

    // Step 4: PIN with confirmation.
    await enterPin(tester, '4829');
    await tapText(tester, 'Next');
    await settle(tester, 5);
    await enterPin(tester, '4829');
    await tapText(tester, 'Confirm PIN');
    await settle(tester);
    expect(find.text('PIN created'), findsOneWidget);
    expect(store.values.values.any((v) => v.contains('4829')), isFalse);
    await tapText(tester, 'Continue');
    await settle(tester);

    // Step 5: finish.
    await tapText(tester, 'Open my dashboard');
    await settle(tester, 30);

    expect(find.textContaining('Money earned so far'), findsOneWidget);
    expect(find.textContaining('Asha'), findsOneWidget);
    final sources = await db.select(db.incomeSources).get();
    expect(sources.single.name, 'Acme');
    expect((await db.select(db.profiles).getSingle()).onboardingComplete, isTrue);
    await done(tester);
  });

  testWidgets('dashboard shows live earnings from persisted rules', (tester) async {
    await phone(tester);
    await seedProfile();
    await tester.pumpWidget(testApp(db: db, store: store, clock: clock));
    await settle(tester, 30);

    // 31,000 in October (31 days): by 12:00 IST on the 15th → 14.5 days → ₹14,500.
    expect(find.textContaining('₹14,500.00'), findsWidgets);
    // Per-day rate ₹1,000 appears in the rates card.
    expect(find.textContaining('₹1,000.00'), findsWidgets);
    expect(find.text('Earning rates'), findsOneWidget);
    await done(tester);
  });

  testWidgets('PIN lock: wrong PIN is rejected, correct PIN unlocks', (tester) async {
    await phone(tester);
    await seedProfile(withSalary: false);
    await PinService(store, clock, iterations: 1000, useIsolate: false).setPin('4829');
    await tester.pumpWidget(testApp(db: db, store: store, clock: clock, hasPin: true));
    await settle(tester);

    expect(find.textContaining('Enter your PIN'), findsOneWidget);
    await enterPin(tester, '1357');
    await tapText(tester, 'Unlock');
    await settle(tester, 5);
    expect(find.textContaining('Incorrect PIN'), findsOneWidget);

    await enterPin(tester, '4829');
    await tapText(tester, 'Unlock');
    await settle(tester, 30);
    expect(find.textContaining('Money earned so far'), findsOneWidget);
    await done(tester);
  });

  testWidgets('customising rates persists and keeps at least one unit', (tester) async {
    await phone(tester);
    await seedProfile();
    await LocalSettingsRepository(db, clock).write(
      'dashboard',
      DashboardConfig.defaults().copyWith(units: [EarningUnit.day], primaryUnit: EarningUnit.day).toJson(),
    );
    await tester.pumpWidget(testApp(db: db, store: store, clock: clock));
    await settle(tester, 30);

    await tapText(tester, 'Customize dashboard');
    await settle(tester);
    // Try to remove the only unit.
    await tester.tap(find.widgetWithText(FilterChip, 'Per day'));
    await settle(tester, 5);
    var saved = DashboardConfig.fromJson((await LocalSettingsRepository(db, clock).read('dashboard'))!);
    expect(saved.units, [EarningUnit.day]);

    await tester.tap(find.widgetWithText(FilterChip, 'Per second'));
    await settle(tester, 5);
    saved = DashboardConfig.fromJson((await LocalSettingsRepository(db, clock).read('dashboard'))!);
    expect(saved.units, containsAll([EarningUnit.day, EarningUnit.second]));
    await done(tester);
  });
}
