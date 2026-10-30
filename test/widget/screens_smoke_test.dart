import 'package:earnlens/app.dart';
import 'package:earnlens/core/clock.dart';
import 'package:earnlens/core/routing/app_router.dart';
import 'package:earnlens/core/security/secure_store.dart';
import 'package:earnlens/data/repositories/local_account_repository.dart';
import 'package:earnlens/data/repositories/local_income_source_repository.dart';
import 'package:earnlens/data/repositories/local_profile_settings_repository.dart';
import 'package:earnlens/data/repositories/local_records_repository.dart';
import 'package:earnlens/domain/models/account.dart';
import 'package:earnlens/domain/models/enums.dart';
import 'package:earnlens/domain/models/profile.dart';
import 'package:earnlens/domain/services/sample_data_service.dart';
import 'package:earnlens/features/accounts/application/account_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_app.dart';
import '../helpers/test_database.dart';

/// Visits every route of the real router with sample data, at phone and
/// desktop widths, and fails with the list of routes that threw or overflowed.
void main() {
  final clock = FixedClock(DateTime.utc(2024, 10, 15, 6, 30));

  for (final size in const [Size(360, 760), Size(1280, 860)]) {
    testWidgets('every screen renders without errors at ${size.width.toInt()}px', (tester) async {
      tester.view.physicalSize = size * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      final db = memoryDatabase();
      final ids = SeqIds();
      await LocalProfileRepository(db).save(UserProfile(
        displayName: 'Asha',
        currencyCode: 'INR',
        locale: 'en_IN',
        timezone: 'Asia/Kolkata',
        onboardingComplete: true,
        createdAt: clock.now(),
        updatedAt: clock.now(),
      ));
      await seedAccount(db);
      final sources = LocalIncomeSourceRepository(db, clock, ids, testScope);
      final records = LocalRecordsRepository(db, clock, ids, testScope);
      await SampleDataService(sources, records, clock, ids).insert(currencyCode: 'INR', today: d(2024, 10, 15));
      final temp = source(id: 'temp', kind: IncomeKind.temporary, start: d(2024, 10, 10), end: d(2024, 10, 24),
          payRule: PayRule.manual, expectedPayDate: d(2024, 10, 30));
      await sources.createSource(temp, initialRate: rev('temp', temp.startDate, 200000, period: RatePeriod.day));
      final all = await sources.sources();
      final salary = all.firstWhere((s) => s.kind == IncomeKind.salary).id;
      final variable = all.firstWhere((s) => s.kind == IncomeKind.variable).id;
      final item = (await db.select(db.compensationItems).get()).first.id;
      final entry = (await db.select(db.ledgerEntries).get()).first.id;
      final rev0 = (await db.select(db.rateRevisions).get()).first.id;
      // A second account (one USD source) and a combined account of both.
      await seedAccount(db, id: 'acc-family', name: 'Family');
      final usd = source(id: 'usd', start: d(2024, 1, 1), currency: 'USD');
      await LocalIncomeSourceRepository(db, clock, ids, AccountScope.single('acc-family'))
          .createSource(usd, initialRate: rev('usd', usd.startDate, 500000));
      await LocalCombinedAccountRepository(db, clock, ids).create(CombinedAccount(
        id: 'combo',
        name: 'Household',
        currencyCode: 'INR',
        memberIds: const ['acc-family', testAccountId],
        createdAt: clock.now(),
        updatedAt: clock.now(),
      ));

      final errors = <String>[];
      var current = '';
      final previous = FlutterError.onError;
      FlutterError.onError = (d) {
        final where = RegExp(r'EarnLens/(lib/[^\s)]+\.dart:\d+)')
            .allMatches(d.toString())
            .map((m) => m.group(1))
            .take(1)
            .join();
        errors.add('${current.isEmpty ? '/home(initial)' : current}: '
            '${d.exceptionAsString().split('\n').first} [$where]');
      };

      await tester.pumpWidget(testApp(db: db, store: InMemorySecureStore(), clock: clock));
      Future<void> settle() async {
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      await settle();
      final container = ProviderScope.containerOf(tester.element(find.byType(EarnLensApp)));
      final router = container.read(routerProvider);

      final routes = [
        '/home',
        '/home/customize',
        '/income',
        for (final k in IncomeKind.values) '/income/new?kind=${k.name}',
        '/income/$salary',
        '/income/$salary/edit',
        '/income/$salary/revision',
        '/income/$salary/revision?rev=$rev0',
        '/income/$salary/item',
        '/income/$salary/item?item=$item',
        '/income/$salary/entry?type=received&period=2024-09',
        '/income/$salary/entry?entry=$entry',
        '/income/$salary/entry?type=adjustment',
        '/income/$variable',
        '/income/$variable/month/2024-09',
        '/income/$variable/entry?type=earned&period=2024-10',
        '/income/temp',
        '/calendar',
        '/insights',
        '/insights/month/2024-09',
        '/insights/what-if',
        '/settings',
        '/settings/profile',
        '/settings/appearance',
        '/settings/dashboard',
        '/settings/calculation',
        '/settings/holidays',
        '/settings/notifications',
        '/settings/security',
        '/settings/security/change-pin',
        '/settings/data',
        '/settings/audit',
        '/settings/about',
        '/settings/privacy',
        '/settings/help',
        '/settings/accounts',
        '/settings/accounts/new',
        '/settings/accounts/$testAccountId',
        '/settings/accounts/$testAccountId/edit',
        '/settings/accounts/$testAccountId/delete',
        '/settings/accounts/combined/new',
        '/settings/accounts/combined/combo',
        '/settings/accounts/combined/combo/members',
        // The same app inside the combined (read-only) account.
        'open:combined',
        '/home',
        '/home/member/$testAccountId',
        '/home/member/acc-family',
        '/income',
        '/income/$salary',
        '/income/$salary/edit',
        '/income/$salary/entry?type=received&period=2024-09',
        '/calendar',
        '/insights',
        '/insights/month/2024-09',
        '/settings',
        '/settings/data',
        '/settings/dashboard',
      ];
      for (final r in routes) {
        if (r == 'open:combined') {
          await container.read(accountControllerProvider).open(const CombinedView('combo'));
          await settle();
          continue;
        }
        current = r;
        router.go(r);
        await settle();
        final e = tester.takeException();
        if (e != null) errors.add('$r: $e');
        // Scroll to the bottom to build lazily created content too.
        final scrollables = find.byType(Scrollable);
        if (scrollables.evaluate().isNotEmpty) {
          await tester.drag(scrollables.first, const Offset(0, -3000), warnIfMissed: false);
          await settle();
        }
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      FlutterError.onError = previous;
      await db.close();
      expect(errors, isEmpty, reason: errors.join('\n'));
    });
  }
}
