import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../notifications/application/notification_service.dart';
import '../../widgets/home_widget_service.dart';

/// What a pull-to-refresh reloads. Everything is local: refreshing re-reads
/// the on-device database and recomputes derived values — it never needs a
/// network connection, writes nothing and cannot create or alter records.
enum RefreshScope {
  /// Earnings snapshot (sources, revisions, items, monthly records, ledger).
  earnings,

  /// User calendar events.
  calendar,

  /// Rate history, pauses and holiday overrides shown on detail screens.
  sourceDetails,

  /// Change history.
  audit,
}

class AppRefresher {
  AppRefresher(this._ref);
  final Ref _ref;
  Future<void>? _inFlight;

  /// Refreshes the requested scopes. Concurrent calls share one operation, so
  /// pulling on two screens (or twice) never runs overlapping reloads.
  Future<void> refresh([Set<RefreshScope> scopes = const {RefreshScope.earnings}]) =>
      _inFlight ??= _run(scopes).whenComplete(() => _inFlight = null);

  Future<void> _run(Set<RefreshScope> scopes) async {
    // Re-evaluate "today" (date roll-over, timezone change after resume).
    _ref.invalidate(todayProvider);
    if (scopes.contains(RefreshScope.calendar)) _ref.invalidate(calendarEventsProvider);
    if (scopes.contains(RefreshScope.sourceDetails)) {
      _ref.invalidate(revisionsProvider);
      _ref.invalidate(pausesProvider);
      _ref.invalidate(overridesProvider);
    }
    if (scopes.contains(RefreshScope.audit)) _ref.invalidate(auditProvider);

    // Re-read authoritative records; previous values stay on screen until the
    // new snapshot arrives (no flicker), and all summaries recompute from it.
    final scope = _ref.read(accountScopeProvider);
    _ref.invalidate(scopedSnapshotProvider(scope));
    if (scope.visibleAccountIds.isNotEmpty) await _ref.read(scopedSnapshotProvider(scope).future);
    if (scopes.contains(RefreshScope.calendar)) await _ref.read(calendarEventsProvider.future);

    _ref.read(notificationServiceProvider).requestSync();
    _ref.read(homeWidgetServiceProvider).requestPublish();
  }
}

final appRefresherProvider = Provider<AppRefresher>((ref) => AppRefresher(ref));
