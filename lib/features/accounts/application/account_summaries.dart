import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/date_time/local_date.dart';
import '../../../data/repositories/local_earnings_data_source.dart';
import '../../../domain/calculation/earnings_snapshot.dart';
import '../../../domain/models/account.dart';
import '../../../domain/money/fraction.dart';

/// Headline figures of one account (or combined account) for lists and the
/// switcher. Computed from that account's own records on demand; nothing is
/// cached in the database.
class AccountSummary {
  const AccountSummary({required this.earnedThisMonth, required this.sourceCount, required this.snapshot});

  /// Earned so far this month in the summary currency.
  final Fraction earnedThisMonth;
  final int sourceCount;
  final EarningsSnapshot snapshot;
}

/// Summary of [scope] in [currencyCode]. Loaded once per open of the list
/// (not live-ticking); PIN-protected accounts are never summarised while
/// locked — callers check that first.
final accountSummaryProvider =
    FutureProvider.autoDispose.family<AccountSummary, (AccountScope, String)>((ref, key) async {
  final (scope, currencyCode) = key;
  final snap = await LocalEarningsDataSource(ref.watch(databaseProvider), scope.visibleAccountIds).loadSnapshot();
  final now = ref.read(clockProvider).now().microsecondsSinceEpoch;
  final today = ref.read(financialCalendarProvider).dateOf(now);
  final earned = ref.read(earningsCalculatorProvider).liveTotal(
        snap,
        DateRange.month(today.yearMonth),
        now,
        currencyCode: currencyCode,
      );
  return AccountSummary(
    earnedThisMonth: earned,
    sourceCount: snap.sources.where((s) => s.currencyCode == currencyCode).length,
    snapshot: snap,
  );
});

/// Whether [account] needs its PIN before its figures may be shown.
final isAccountLockedProvider = Provider.family<bool, String>((ref, accountId) {
  final a = ref.watch(accountByIdProvider(accountId));
  return a != null && a.requiresPin && !ref.watch(accountUnlocksProvider).contains(accountId);
});

/// Member accounts of a combined account, in switcher order.
final combinedMembersProvider = Provider.family<List<Account>, String>((ref, combinedId) {
  final ids = ref.watch(combinedByIdProvider(combinedId))?.memberIds.toSet() ?? const {};
  return [
    for (final a in ref.watch(accountsProvider))
      if (ids.contains(a.id)) a,
  ];
});
