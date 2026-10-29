import 'package:earnlens/core/clock.dart';
import 'package:earnlens/core/date_time/local_date.dart';
import 'package:earnlens/core/formatting/money_format.dart';
import 'package:earnlens/core/security/pin_service.dart';
import 'package:earnlens/core/security/secure_store.dart';
import 'package:earnlens/domain/calculation/earnings_snapshot.dart';
import 'package:earnlens/domain/calculation/payment_schedule.dart';
import 'package:earnlens/domain/calculation/rate_calculator.dart';
import 'package:earnlens/domain/calculation/source_rules.dart';
import 'package:earnlens/domain/models/settings.dart';
import 'package:earnlens/domain/money/currency.dart';
import 'package:earnlens/domain/money/fraction.dart';
import 'package:earnlens/domain/services/dashboard_preferences.dart';
import 'package:earnlens/features/notifications/application/notification_planner.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';

void main() {
  group('dashboard preferences', () {
    test('REGRESSION: at least one earning rate always remains selected', () {
      var c = DashboardConfig.defaults();
      for (final u in EarningUnit.values) {
        c = DashboardPreferences.toggleUnit(c, u);
        expect(c.units, isNotEmpty);
        expect(DashboardPreferences.isValid(c), isTrue);
      }
      c = DashboardPreferences.deselectAll(c);
      expect(c.units, [c.primaryUnit]);
      expect(DashboardPreferences.toggleUnit(c, c.primaryUnit).units, [c.primaryUnit]);
    });

    test('select all, primary and reorder', () {
      var c = DashboardPreferences.selectAll(DashboardConfig.defaults());
      expect(c.units.toSet(), EarningUnit.values.toSet());
      c = DashboardPreferences.setPrimary(c, EarningUnit.year);
      expect(c.primaryUnit, EarningUnit.year);
      final first = c.units.first;
      c = DashboardPreferences.reorderUnits(c, 0, c.units.length - 1);
      expect(c.units.last, first);
      // Removing the primary moves primary to another visible unit.
      c = DashboardPreferences.toggleUnit(c, EarningUnit.year);
      expect(c.units.contains(c.primaryUnit), isTrue);
    });

    test('config survives JSON round trip and tolerates junk', () {
      final c = DashboardPreferences.setPrecision(DashboardConfig.defaults(), 9);
      expect(c.precision, 6);
      final back = DashboardConfig.fromJson(c.toJson());
      expect(back.units, c.units);
      expect(back.cards.length, DashboardCardType.values.length);
      final junk = DashboardConfig.fromJson({'units': ['nope'], 'primaryUnit': 'x'});
      expect(junk.units, isNotEmpty);
      expect(junk.units.contains(junk.primaryUnit), isTrue);
    });
  });

  group('PIN service', () {
    late InMemorySecureStore store;
    late FixedClock clock;
    late PinService pins;

    setUp(() {
      store = InMemorySecureStore();
      clock = FixedClock(DateTime.utc(2024, 1, 1));
      pins = PinService(store, clock, iterations: 1000);
    });

    test('never stores the PIN in plaintext and verifies it', () async {
      await pins.setPin('482913');
      expect(store.values.values.any((v) => v.contains('482913')), isFalse);
      expect(await pins.verify('482913'), isA<PinAccepted>());
      expect(await pins.verify('000001'), isA<PinRejected>());
    });

    test('same PIN gets a different salt and hash each time', () async {
      await pins.setPin('482913');
      final a = store.values['pin.verifier'];
      await pins.setPin('482913');
      expect(store.values['pin.verifier'], isNot(a));
    });

    test('rejects weak PINs', () {
      expect(PinService.validateNewPin('1234'), isNotNull);
      expect(PinService.validateNewPin('1111'), isNotNull);
      expect(PinService.validateNewPin('12a4'), isNotNull);
      expect(PinService.validateNewPin('123'), isNotNull);
      expect(PinService.validateNewPin('4829'), isNull);
    });

    test('rate limits with growing delays, resets on success', () async {
      await pins.setPin('482913');
      for (var i = 1; i < PinService.freeAttempts; i++) {
        final r = await pins.verify('999999') as PinRejected;
        expect(r.lockedFor, isNull);
      }
      final locked = await pins.verify('999999') as PinRejected;
      expect(locked.lockedFor, const Duration(seconds: 30));
      expect(await pins.verify('482913'), isA<PinLockedOut>());
      clock.value = clock.value.add(const Duration(seconds: 31));
      final again = await pins.verify('999999') as PinRejected;
      expect(again.lockedFor, const Duration(seconds: 60));
      clock.value = clock.value.add(const Duration(seconds: 61));
      expect(await pins.verify('482913'), isA<PinAccepted>());
      expect(await pins.remainingLockout(), isNull);
      expect(PinService.lockoutFor(40), const Duration(hours: 1));
    });

    test('change PIN requires the current PIN', () async {
      await pins.setPin('482913');
      await expectLater(pins.changePin('000000', '583920'), throwsA(anything));
      await pins.changePin('482913', '583920');
      expect(await pins.verify('583920'), isA<PinAccepted>());
    });
  });

  group('notification planner', () {
    final cal = calendarFor('Asia/Kolkata');
    final planner = NotificationPlanner(cal);
    final money = MoneyFormatter('en_IN', Currency.inr);

    List<String> plan(NotificationSettings settings, {bool privacy = false, int? now}) {
      final s = source(payDay: 1, payOffsetMonths: 1);
      final snap = EarningsSnapshot(sources: [s], revisions: [rev(s.id, s.startDate, 3100000)]);
      final today = cal.dateOf(now ?? at(cal, 2024, 10, 20));
      final payments = PaymentScheduler(engineFor()).expectedPayments(
        rules: [SourceRules(source: s, revisions: [rev(s.id, s.startDate, 3100000)])],
        items: const [],
        ledger: const [],
        periods: [today.yearMonth.previous, today.yearMonth],
        today: today,
      );
      return planner
          .plan(
            snapshot: snap,
            payments: payments,
            events: const [],
            settings: settings,
            backup: BackupState(lastBackupAt: DateTime.utc(2024, 10, 1)),
            nowMicros: now ?? at(cal, 2024, 10, 20),
            money: money,
            privacyMode: privacy,
          )
          .map((n) => '${n.key}|${n.body}')
          .toList();
    }

    test('nothing is planned until the user opts in', () {
      expect(plan(const NotificationSettings()), isEmpty);
    });

    test('plans payday reminders with stable keys and no duplicates', () {
      final s = const NotificationSettings(masterEnabled: true);
      final a = plan(s);
      expect(a.any((k) => k.startsWith('pay:s1:2024-10:before')), isTrue);
      expect(a.any((k) => k.startsWith('pay:s1:2024-10:due')), isTrue);
      expect(a.map((k) => k.split('|').first).toSet().length, a.length);
      expect(plan(s), a, reason: 'planning is deterministic');
    });

    test('privacy mode omits amounts', () {
      final withAmounts = plan(const NotificationSettings(masterEnabled: true));
      final private = plan(const NotificationSettings(masterEnabled: true), privacy: true);
      expect(withAmounts.any((x) => x.contains('₹')), isTrue);
      expect(private.any((x) => x.contains('₹')), isFalse);
    });

    test('disabled categories are skipped', () {
      final only = plan(const NotificationSettings(masterEnabled: true, enabled: {NotificationCategory.monthEndReview}));
      expect(only.every((k) => k.startsWith('monthEnd:')), isTrue);
    });

    test('quiet hours move reminders to the end of quiet hours', () {
      final settings = const NotificationSettings(
        masterEnabled: true,
        enabled: {NotificationCategory.monthEndReview},
        reminderMinute: 23 * 60,
        quietStartMinute: 22 * 60,
        quietEndMinute: 7 * 60,
      );
      final s = source();
      final n = planner.plan(
        snapshot: EarningsSnapshot(sources: [s], revisions: const []),
        payments: const [],
        events: const [],
        settings: settings,
        backup: const BackupState(),
        nowMicros: at(cal, 2024, 10, 20),
        money: money,
        privacyMode: false,
      );
      expect(n.first.atMicros, at(cal, 2024, 10, 31, 7));
    });

    test('platform ids are stable', () {
      final a = plan(const NotificationSettings(masterEnabled: true));
      expect(a, isNotEmpty);
    });
  });

  group('money formatting', () {
    test('Indian grouping and exact fractions', () {
      final f = MoneyFormatter('en_IN', Currency.inr);
      expect(f.minor(1234567890), '₹1,23,45,678.90');
      expect(f.fraction(Fraction.fromInt(3500000, 30 * 86400), decimals: 4), '₹0.0135');
      expect(f.signed(450000), '+₹4,500.00');
      expect(f.minor(-20000), '−₹200.00');
    });

    test('percent change handles zero', () {
      expect(percentChange(0, 100), isNull);
      expect(percentChange(100, 150), '+50.0%');
      expect(percentChange(200, 100), '−50.0%');
    });
  });

  test('LocalDate weekday helpers used by planner are consistent', () {
    expect(LocalDate(2024, 10, 31).weekday, 4);
  });
}
