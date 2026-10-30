import 'package:drift/drift.dart' show Value;
import 'package:earnlens/app.dart';
import 'package:earnlens/bootstrap/dependency_injection.dart';
import 'package:earnlens/core/clock.dart';
import 'package:earnlens/core/routing/app_router.dart';
import 'package:earnlens/core/security/pin_service.dart';
import 'package:earnlens/core/security/secure_store.dart';
import 'package:earnlens/data/repositories/local_account_repository.dart';
import 'package:earnlens/data/repositories/local_income_source_repository.dart';
import 'package:earnlens/data/repositories/local_profile_settings_repository.dart';
import 'package:earnlens/database/app_database.dart';
import 'package:earnlens/domain/models/account.dart';
import 'package:earnlens/domain/models/profile.dart';
import 'package:earnlens/features/accounts/application/account_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_app.dart';
import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late InMemorySecureStore store;
  late SeqIds ids;
  final clock = FixedClock(DateTime.utc(2024, 10, 15, 6, 30));
  const family = 'acc-family';

  setUp(() {
    db = memoryDatabase();
    store = InMemorySecureStore();
    ids = SeqIds();
  });

  Future<void> settle(WidgetTester tester, [int frames = 20]) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> done(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    await db.close();
  }

  Future<void> phone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  /// Profile, "Personal" with a ₹31,000 salary and "Family" with ₹50,000.
  Future<void> seed() async {
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
    await seedAccount(db, id: family, name: 'Family');
    final sal = source(id: 'sal', start: d(2024, 1, 1));
    await LocalIncomeSourceRepository(db, clock, ids, testScope)
        .createSource(sal, initialRate: rev('sal', sal.startDate, 3100000));
    final fam = source(id: 'fam', start: d(2024, 1, 1));
    await LocalIncomeSourceRepository(db, clock, ids, AccountScope.single(family))
        .createSource(fam, initialRate: rev('fam', fam.startDate, 5000000));
  }

  Future<void> combine({String id = 'home', List<String> members = const [family, testAccountId]}) =>
      LocalCombinedAccountRepository(db, clock, ids).create(CombinedAccount(
        id: id,
        name: 'Home',
        currencyCode: 'INR',
        memberIds: members,
        createdAt: clock.now(),
        updatedAt: clock.now(),
      ));

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(EarnLensApp)));

  Future<int> financialRows() async =>
      (await db.select(db.incomeSources).get()).length +
      (await db.select(db.rateRevisions).get()).length +
      (await db.select(db.ledgerEntries).get()).length;

  /// The list of the screen on top (routes below it are offstage).
  Finder pageScrollable() => find.descendant(of: find.byType(ListView).last, matching: find.byType(Scrollable)).first;

  Future<void> openSwitcher(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Switch account').first);
    await settle(tester, 8);
  }

  testWidgets('switching shows only the chosen account and changes no records', (tester) async {
    await phone(tester);
    await seed();
    await tester.pumpWidget(testApp(db: db, store: store, clock: clock));
    await settle(tester, 30);
    final container = containerOf(tester);
    expect(container.read(activeViewProvider), const IndividualView(testAccountId));
    expect(container.read(snapshotProvider).sources.map((s) => s.id), ['sal']);
    final before = await financialRows();

    await openSwitcher(tester);
    expect(find.text('2/10'), findsOneWidget);
    expect(find.text('Family'), findsWidgets);
    await tester.tap(find.text('Family').last);
    await settle(tester, 15);

    expect(container.read(activeViewProvider), const IndividualView(family));
    expect(container.read(snapshotProvider).sources.map((s) => s.id), ['fam']);
    expect(await financialRows(), before);
    // The choice is remembered for the next launch.
    final saved = await LocalSettingsRepository(db, clock).read(SettingsKeys.activeView);
    expect(AccountView.fromJson(saved), const IndividualView(family));
    await done(tester);
  });

  testWidgets('creates an account from the switcher and opens it', (tester) async {
    await phone(tester);
    await seed();
    await tester.pumpWidget(testApp(db: db, store: store, clock: clock));
    await settle(tester, 30);
    await openSwitcher(tester);
    await tester.tap(find.text('New account'));
    await settle(tester, 10);

    await tester.enterText(find.widgetWithText(TextFormField, 'Account name'), 'Studio');
    final create = find.text('Create account');
    await tester.scrollUntilVisible(create, 300, scrollable: pageScrollable());
    await tester.tap(create);
    await settle(tester, 20);

    final accounts = await db.select(db.accounts).get();
    expect(accounts.map((a) => a.name), containsAll(['Personal', 'Family', 'Studio']));
    final studio = accounts.firstWhere((a) => a.name == 'Studio');
    expect(containerOf(tester).read(activeViewProvider), IndividualView(studio.id));
    expect(containerOf(tester).read(snapshotProvider).sources, isEmpty);
    await done(tester);
  });

  testWidgets('at 10 accounts the switcher explains the limit', (tester) async {
    await phone(tester);
    await seed();
    for (var i = 3; i <= 10; i++) {
      await seedAccount(db, id: 'acc-$i', name: 'Account $i');
    }
    await tester.pumpWidget(testApp(db: db, store: store, clock: clock));
    await settle(tester, 30);
    await openSwitcher(tester);
    expect(find.text('10/10'), findsOneWidget);
    expect(find.textContaining('reached the limit of 10 accounts'), findsOneWidget);
    await tester.tap(find.text('New account'));
    await settle(tester, 8);
    expect(find.widgetWithText(TextFormField, 'Account name'), findsNothing);
    await done(tester);
  });

  testWidgets('picking the same members in another order points to the existing combination', (tester) async {
    await phone(tester);
    await seed();
    await combine(members: const [family, testAccountId]);
    await tester.pumpWidget(testApp(db: db, store: store, clock: clock));
    await settle(tester, 30);
    containerOf(tester).read(routerProvider).go('/settings/accounts/combined/new');
    await settle(tester, 10);

    final personalBox = find.widgetWithText(CheckboxListTile, 'Personal');
    await tester.ensureVisible(personalBox);
    await tester.pump();
    await tester.tap(personalBox);
    await tester.pump();
    final familyBox = find.widgetWithText(CheckboxListTile, 'Family');
    await tester.ensureVisible(familyBox);
    await tester.pump();
    await tester.tap(familyBox);
    await settle(tester, 5);
    expect(find.textContaining('already combined as "Home"'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Again');
    final create = find.text('Create combined account');
    await tester.drag(find.byType(ListView).last, const Offset(0, -1200));
    await settle(tester, 3);
    await tester.tap(create);
    await settle(tester, 5);
    expect((await db.select(db.combinedAccounts).get()).length, 1);
    await done(tester);
  });

  testWidgets('a combined account adds up members, is read-only, and links to the owner', (tester) async {
    await phone(tester);
    await seed();
    await combine();
    await tester.pumpWidget(testApp(db: db, store: store, clock: clock));
    await settle(tester, 30);
    final container = containerOf(tester);
    await container.read(accountControllerProvider).open(const CombinedView('home'));
    await settle(tester, 20);

    expect(container.read(snapshotProvider).sources.map((s) => s.id).toSet(), {'sal', 'fam'});
    expect(container.read(isReadOnlyViewProvider), isTrue);
    expect(find.text('Members this month'), findsOneWidget);

    final router = container.read(routerProvider);
    router.go('/income');
    await settle(tester, 10);
    expect(find.text('Add income'), findsNothing);

    router.go('/income/sal/edit');
    await settle(tester, 10);
    expect(find.text('Combined accounts are read-only'), findsOneWidget);
    await tester.tap(find.text('Open Personal'));
    await settle(tester, 20);
    expect(container.read(activeViewProvider), const IndividualView(testAccountId));
    expect(find.text('Combined accounts are read-only'), findsNothing);
    await done(tester);
  });

  testWidgets('a PIN-protected account stays covered until its PIN is entered', (tester) async {
    await phone(tester);
    await seed();
    await PinService(store, clock, iterations: 1000, useIsolate: false).forAccount(family).setPin('2580');
    await (db.update(db.accounts)..where((t) => t.id.equals(family)))
        .write(const AccountsCompanion(requiresPin: Value(true)));
    await tester.pumpWidget(testApp(db: db, store: store, clock: clock));
    await settle(tester, 30);
    final container = containerOf(tester);

    await container.read(accountControllerProvider).open(const IndividualView(family));
    await settle(tester, 15);
    expect(find.text('Family is protected'), findsOneWidget);
    // Nothing of the protected account is loaded while it is locked.
    expect(container.read(accountScopeProvider).visibleAccountIds, isEmpty);

    await tester.tap(find.text('Unlock').first);
    await settle(tester, 8);
    for (final ch in '2580'.split('')) {
      await tester.tap(find.text(ch).last);
      await tester.pump();
    }
    await tester.tap(find.text('Unlock').last);
    await settle(tester, 20);
    expect(find.text('Family is protected'), findsNothing);
    expect(container.read(snapshotProvider).sources.map((s) => s.id), ['fam']);
    await done(tester);
  });

  testWidgets('archiving the open account opens the next one and keeps its data', (tester) async {
    await phone(tester);
    await seed();
    await tester.pumpWidget(testApp(db: db, store: store, clock: clock));
    await settle(tester, 30);
    final container = containerOf(tester);
    final before = await financialRows();
    await container.read(accountControllerProvider).setArchived(testAccountId, archived: true);
    await settle(tester, 15);
    expect(container.read(activeViewProvider), const IndividualView(family));
    expect(container.read(snapshotProvider).sources.map((s) => s.id), ['fam']);
    expect(await financialRows(), before);
    await openSwitcher(tester);
    expect(find.text('Personal'), findsNothing, reason: 'archived accounts are hidden from the switcher');
    await done(tester);
  });

  testWidgets('deleting an account requires its name and removes only its data', (tester) async {
    await phone(tester);
    await seed();
    await combine();
    await tester.pumpWidget(testApp(db: db, store: store, clock: clock));
    await settle(tester, 30);
    containerOf(tester).read(routerProvider).go('/settings/accounts/$family/delete');
    await settle(tester, 15);

    final delete = find.text('Delete account permanently');
    await tester.ensureVisible(delete);
    await tester.tap(delete);
    await settle(tester, 5);
    expect((await db.select(db.accounts).get()).length, 2);

    await tester.enterText(find.byType(TextField).last, 'Family');
    await settle(tester, 3);
    await tester.ensureVisible(delete);
    await tester.tap(delete);
    await settle(tester, 20);

    expect((await db.select(db.accounts).get()).map((a) => a.id), [testAccountId]);
    expect((await db.select(db.incomeSources).get()).map((s) => s.id), ['sal']);
    expect(await db.select(db.combinedAccounts).get(), isEmpty);
    await done(tester);
  });
}
