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
      title: 'Earned this month',
      checkpoints: points,
      rateText: '${money.fraction(rate, decimals: dash.primaryUnit.isSubDay ? dash.precision : 2)} ${dash.primaryUnit.shortLabel}',
      hidden: ref.read(securitySettingsProvider).hideAmountsOnWidget,
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
  ref.listen(dashboardConfigProvider, (_, _) => s.requestPublish());
  ref.listen(securitySettingsProvider, (_, _) => s.requestPublish());
  ref.listen(profileStreamProvider, (_, _) => s.requestPublish());
  ref.listen(todayProvider, (_, _) => s.requestPublish());
  s.requestPublish();
});
