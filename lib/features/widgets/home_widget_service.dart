import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bootstrap/dependency_injection.dart';
import '../../core/date_time/local_date.dart';
import 'home_widget_bridge.dart';

/// Publishes precomputed, exact values to the home-screen widget.
///
/// The OS refreshes widgets on its own schedule (about every 30 minutes on
/// Android), so instead of claiming per-second updates the app stores a value
/// for every 30-minute checkpoint over the next 24 hours; the widget displays
/// the latest checkpoint with its time.
///
/// The widget shows the open account (or combined account). Nothing is
/// published while that account's data is loading or PIN-locked, and amounts
/// are hidden whenever a PIN-protected account is part of the view.
class HomeWidgetService {
  HomeWidgetService(this.ref);
  final Ref ref;
  Timer? _debounce;

  static const interval = Duration(minutes: 30);
  static const checkpoints = 49;

  void requestPublish() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 3), _publish);
  }

  void dispose() => _debounce?.cancel();

  Future<void> _publish() async {
    final bridge = ref.read(homeWidgetBridgeProvider);
    if (!bridge.isSupported) return;
    if (ref.read(profileStreamProvider).value?.onboardingComplete != true) return;
    // Never publish an empty or another account's snapshot.
    if (ref.read(accountScopeProvider).visibleAccountIds.isEmpty) return;
    if (!ref.read(snapshotStreamProvider).hasValue) return;
    final accounts = ref.read(accountsProvider);
    final viewIds = ref.read(viewAccountIdsProvider);
    final protected = accounts.any((a) => viewIds.contains(a.id) && a.requiresPin);
    final viewName = ref.read(activeAccountProvider)?.name ?? ref.read(activeCombinedProvider)?.name;
    final now = ref.read(clockProvider).now();
    final calendar = ref.read(financialCalendarProvider);
    final calc = ref.read(earningsCalculatorProvider);
    final snap = ref.read(snapshotProvider);
    final money = ref.read(moneyFormatterProvider);
    final currency = ref.read(currencyProvider).code;
    final dash = ref.read(dashboardConfigProvider);
    final today = calendar.today(now);

    final start = now.millisecondsSinceEpoch - now.millisecondsSinceEpoch % interval.inMilliseconds;
    final points = <WidgetCheckpoint>[];
    for (var i = 0; i < checkpoints; i++) {
      final at = start + i * interval.inMilliseconds;
      final micros = at * 1000;
      final day = calendar.dateOf(micros);
      final value = calc.liveTotal(snap, DateRange.month(day.yearMonth), micros, currencyCode: currency);
      points.add(WidgetCheckpoint(at, money.fraction(value)));
    }
    final rate = calc.combinedRate(snap, dash.primaryUnit, today, currencyCode: currency, basis: dash.rateBasis);
    await bridge.publish(WidgetPayload(
      title: accounts.length > 1 && viewName != null ? '$viewName · this month' : 'Earned this month',
      checkpoints: points,
      rateText: '${dash.primaryUnit.isSubDay ? money.rate(rate, decimals: dash.precision) : money.fraction(rate)} '
          '${dash.primaryUnit.shortLabel}',
      hidden: protected || ref.read(securitySettingsProvider).hideAmountsOnWidget,
      generatedAtMillis: now.millisecondsSinceEpoch,
    ));
  }
}

final homeWidgetServiceProvider = Provider<HomeWidgetService>((ref) {
  final s = HomeWidgetService(ref);
  ref.onDispose(s.dispose);
  return s;
});

final homeWidgetSyncProvider = Provider<void>((ref) {
  final s = ref.watch(homeWidgetServiceProvider);
  ref.listen(snapshotProvider, (_, _) => s.requestPublish());
  ref.listen(activeViewProvider, (_, _) => s.requestPublish());
  ref.listen(accountsProvider, (_, _) => s.requestPublish());
  ref.listen(dashboardConfigProvider, (_, _) => s.requestPublish());
  ref.listen(securitySettingsProvider, (_, _) => s.requestPublish());
  ref.listen(profileStreamProvider, (_, _) => s.requestPublish());
  ref.listen(todayProvider, (_, _) => s.requestPublish());
  s.requestPublish();
});
