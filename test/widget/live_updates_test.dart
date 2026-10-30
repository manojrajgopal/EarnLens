import 'package:earnlens/app.dart';
import 'package:earnlens/bootstrap/dependency_injection.dart';
import 'package:earnlens/core/clock.dart';
import 'package:earnlens/core/routing/app_router.dart';
import 'package:earnlens/core/security/secure_store.dart';
import 'package:earnlens/data/repositories/local_income_source_repository.dart';
import 'package:earnlens/data/repositories/local_profile_settings_repository.dart';
import 'package:earnlens/data/repositories/local_records_repository.dart';
import 'package:earnlens/domain/models/profile.dart';
import 'package:earnlens/domain/models/settings.dart';
import 'package:earnlens/domain/services/sample_data_service.dart';
import 'package:earnlens/features/dashboard/application/dashboard_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_app.dart';
import '../helpers/test_database.dart';

void main() {
  testWidgets('earned-so-far figures update live on screen without a refresh', (tester) async {
    // Tall viewport so every dashboard card is built and listening.
    tester.view.physicalSize = const Size(412, 2600) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final clock = FixedClock(DateTime.utc(2026, 10, 29, 4, 30));
    final db = memoryDatabase();
    final ids = SeqIds();
    await LocalProfileRepository(db).save(UserProfile(
      displayName: 'Test',
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
    final container = ProviderScope.containerOf(tester.element(find.byType(EarnLensApp)));
    final money = container.read(moneyFormatterProvider);
    final month = container.read(todayProvider).yearMonth;
    int earned() => container.read(monthSummaryForProvider(month)).actual;
    int sources() => container.read(monthSummaryProvider(DashboardCardType.sources)).actual;
    int trendNow() => container.read(trendProvider(6)).last.actual;

    final before = (earned(), sources(), trendNow());
    expect(find.text(money.minor(before.$1)), findsWidgets, reason: 'expected vs actual shows earned so far');

    // Two hours pass; only the ticker runs — no data change, no refresh.
    clock.value = clock.value.add(const Duration(hours: 2));
    await tester.pump(const Duration(seconds: 1));
    await settle();

    final after = (earned(), sources(), trendNow());
    expect(after.$1, greaterThan(before.$1), reason: 'expected vs actual accrues');
    expect(after.$2, greaterThan(before.$2), reason: 'income source cards accrue');
    expect(after.$3, greaterThan(before.$3), reason: 'the trend bar for this month accrues');
    expect(find.text(money.minor(after.$1)), findsWidgets, reason: 'new value is on screen');
    expect(find.text(money.minor(before.$1)), findsNothing, reason: 'old value is gone');
    expect(find.text('LIVE'), findsOneWidget, reason: 'only the hero carries the live label');

    // Past months stay fixed.
    final history = container.read(trendProvider(6)).take(5).map((s) => s.actual).toList();
    clock.value = clock.value.add(const Duration(hours: 1));
    await tester.pump(const Duration(seconds: 1));
    await settle();
    expect(container.read(trendProvider(6)).take(5).map((s) => s.actual).toList(), history);

    // The income list's "Earned so far this month" also accrues.
    final router = container.read(routerProvider);
    router.go('/income');
    await settle();
    String listAmount() => (tester.widget<Text>(find
            .descendant(
              of: find.ancestor(of: find.text('Earned so far this month'), matching: find.byType(Column)).first,
              matching: find.textContaining('₹'),
            )
            .first))
        .data!;
    final listBefore = listAmount();
    clock.value = clock.value.add(const Duration(hours: 2));
    await tester.pump(const Duration(seconds: 1));
    await settle();
    expect(listAmount(), isNot(listBefore));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    await db.close();
  });
}
