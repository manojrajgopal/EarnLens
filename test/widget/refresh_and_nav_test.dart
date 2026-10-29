import 'dart:async';

import 'package:earnlens/app.dart';
import 'package:earnlens/core/clock.dart';
import 'package:earnlens/core/routing/app_router.dart';
import 'package:earnlens/core/security/secure_store.dart';
import 'package:earnlens/data/repositories/local_income_source_repository.dart';
import 'package:earnlens/data/repositories/local_profile_settings_repository.dart';
import 'package:earnlens/domain/models/profile.dart';
import 'package:earnlens/shared/widgets/earnlens_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_app.dart';
import '../helpers/test_database.dart';

Widget _host({required Future<void> Function() onRefresh, int items = 30, Widget? header}) => MaterialApp(
      home: Scaffold(
        body: EarnLensRefreshIndicator(
          onRefresh: onRefresh,
          minimumVisible: Duration.zero,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
            children: [
              ?header,
              for (var i = 0; i < items; i++) SizedBox(height: 60, child: Text('row $i')),
            ],
          ),
        ),
      ),
    );

Future<void> _pull(WidgetTester tester, double dy, {Offset from = const Offset(200, 200)}) async {
  final g = await tester.startGesture(from);
  for (var i = 0; i < 10; i++) {
    await g.moveBy(Offset(0, dy / 10));
    await tester.pump(const Duration(milliseconds: 16));
  }
  await g.up();
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  group('EarnLensRefreshIndicator', () {
    testWidgets('a pull past the threshold refreshes once and closes', (tester) async {
      var calls = 0;
      await tester.pumpWidget(_host(onRefresh: () async => calls++));
      await _pull(tester, 400);
      await _settle(tester);
      expect(calls, 1);
      final state = tester.state<EarnLensRefreshIndicatorState>(find.byType(EarnLensRefreshIndicator));
      expect(state.isRefreshing, isFalse);
      expect(find.text('Updated'), findsNothing, reason: 'indicator is gone after completion');
    });

    testWidgets('a short pull does not refresh', (tester) async {
      var calls = 0;
      await tester.pumpWidget(_host(onRefresh: () async => calls++));
      await _pull(tester, 40);
      await _settle(tester);
      expect(calls, 0);
    });

    testWidgets('normal scrolling down never refreshes', (tester) async {
      var calls = 0;
      await tester.pumpWidget(_host(onRefresh: () async => calls++));
      await _pull(tester, -600);
      await _settle(tester);
      await _pull(tester, 300); // scrolls back up, but did not start at the top
      await _settle(tester);
      expect(calls, 0);
    });

    testWidgets('pulls during a refresh are ignored (no concurrent refreshes)', (tester) async {
      var calls = 0;
      final gate = Completer<void>();
      await tester.pumpWidget(_host(onRefresh: () {
        calls++;
        return gate.future;
      }));
      await _pull(tester, 400);
      await tester.pump(const Duration(milliseconds: 300));
      await _pull(tester, 400);
      await tester.pump(const Duration(milliseconds: 300));
      expect(calls, 1);
      gate.complete();
      await _settle(tester);
      expect(calls, 1);
    });

    testWidgets('an error still closes the indicator', (tester) async {
      await tester.pumpWidget(_host(onRefresh: () async => throw StateError('db unavailable')));
      await _pull(tester, 400);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text("Couldn't refresh"), findsOneWidget);
      await _settle(tester);
      final state = tester.state<EarnLensRefreshIndicatorState>(find.byType(EarnLensRefreshIndicator));
      expect(state.isRefreshing, isFalse);
      expect(find.text("Couldn't refresh"), findsNothing);
    });

    testWidgets('works on an empty list', (tester) async {
      var calls = 0;
      await tester.pumpWidget(_host(onRefresh: () async => calls++, items: 0));
      await _pull(tester, 400);
      await _settle(tester);
      expect(calls, 1);
    });

    testWidgets('horizontal carousels inside do not trigger it', (tester) async {
      var calls = 0;
      await tester.pumpWidget(_host(
        onRefresh: () async => calls++,
        header: SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [for (var i = 0; i < 20; i++) const SizedBox(width: 100, child: Text('card'))],
          ),
        ),
      ));
      final g = await tester.startGesture(const Offset(200, 60));
      for (var i = 0; i < 10; i++) {
        await g.moveBy(const Offset(60, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await _settle(tester);
      expect(calls, 0);
    });
  });

  group('app refresh & navigation', () {
    final clock = FixedClock(DateTime.utc(2024, 10, 15, 6, 30));

    Future<dynamic> seeded() async {
      final db = memoryDatabase();
      await LocalProfileRepository(db).save(UserProfile(
        displayName: 'Asha',
        currencyCode: 'INR',
        locale: 'en_IN',
        timezone: 'Asia/Kolkata',
        onboardingComplete: true,
        createdAt: clock.now(),
        updatedAt: clock.now(),
      ));
      final s = source(id: 'sal', start: d(2024, 1, 1));
      await LocalIncomeSourceRepository(db, clock, SeqIds()).createSource(s, initialRate: rev('sal', s.startDate, 3100000));
      return db;
    }

    testWidgets('pulling the dashboard reloads data without creating records', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final db = await seeded();
      await tester.pumpWidget(testApp(db: db, store: InMemorySecureStore(), clock: clock));
      await _settle(tester);
      final before = (await db.select(db.ledgerEntries).get()).length + (await db.select(db.rateRevisions).get()).length;
      expect(find.textContaining('₹14,500.00'), findsWidgets);

      await _pull(tester, 420, from: const Offset(200, 300));
      await _settle(tester);
      await _settle(tester);

      final after = (await db.select(db.ledgerEntries).get()).length + (await db.select(db.rateRevisions).get()).length;
      expect(after, before, reason: 'refreshing must never write records');
      expect(find.textContaining('₹14,500.00'), findsWidgets, reason: 'same authoritative value after refresh');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      await db.close();
    });

    testWidgets('tabs keep their state; back at a tab root returns Home', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final db = await seeded();
      await tester.pumpWidget(testApp(db: db, store: InMemorySecureStore(), clock: clock));
      await _settle(tester);
      final router = ProviderScope.containerOf(tester.element(find.byType(EarnLensApp))).read(routerProvider);

      // Open a detail page inside the Income tab, switch to Calendar, come back.
      await tester.tap(find.bySemanticsLabel('Income').last);
      await _settle(tester);
      router.push('/income/sal');
      await _settle(tester);
      expect(router.state.matchedLocation, '/income/sal');
      await tester.tap(find.bySemanticsLabel('Calendar').last);
      await _settle(tester);
      await tester.tap(find.bySemanticsLabel('Income').last);
      await _settle(tester);
      expect(router.state.matchedLocation, '/income/sal', reason: 'tab stack preserved');

      // Back pops within the tab first, then returns to Home from the tab root.
      await tester.binding.handlePopRoute();
      await _settle(tester);
      expect(router.state.matchedLocation, '/income');
      await tester.binding.handlePopRoute();
      await _settle(tester);
      expect(router.state.matchedLocation, '/home');

      // The Analytics destination opens Insights.
      await tester.tap(find.bySemanticsLabel('Analytics').last);
      await _settle(tester);
      expect(router.state.matchedLocation, '/insights');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      await db.close();
    });
  });
}
