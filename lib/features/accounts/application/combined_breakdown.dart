import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/date_time/local_date.dart';
import '../../../domain/calculation/earnings_calculator.dart';
import '../../../domain/calculation/earnings_snapshot.dart';
import '../../../domain/models/account.dart';
import '../../../domain/money/fraction.dart';
import 'account_summaries.dart';

/// One member's part of a combined account this month. Every figure comes
/// from the member's own records ([EarningsSnapshot.subset]) through the
/// same calculator as everywhere else.
class MemberContribution {
  const MemberContribution({
    required this.account,
    required this.snapshot,
    required this.month,
    required this.earned,
    required this.share,
    required this.otherCurrencies,
  });

  final Account account;

  /// The member's records only.
  final EarningsSnapshot snapshot;
  final PeriodSummary month;

  /// Earned so far this month in the combined account's currency.
  final Fraction earned;

  /// Fraction of the combined total (0–1); 0 when the total is zero.
  final double share;

  /// Earned this month in currencies other than the combined currency,
  /// which are listed separately and never added in.
  final Map<String, Fraction> otherCurrencies;
}

/// Contributions of each member of the active combined account (empty in an
/// individual view). Refreshes every minute and whenever records change.
final memberContributionsProvider = Provider<List<MemberContribution>>((ref) {
  final combined = ref.watch(activeCombinedProvider);
  if (combined == null) return const [];
  ref.watch(minuteTickerProvider);
  final snap = ref.watch(snapshotProvider);
  final calc = ref.watch(earningsCalculatorProvider);
  final now = ref.watch(clockProvider).now().microsecondsSinceEpoch;
  final range = DateRange.month(ref.watch(todayProvider).yearMonth);
  final code = combined.currencyCode;
  final members = ref.watch(combinedMembersProvider(combined.id));
  final rows = <(Account, EarningsSnapshot, PeriodSummary, Map<String, Fraction>)>[];
  for (final m in members) {
    final own = snap.subset({m.id});
    final others = <String, Fraction>{
      for (final cur in {for (final s in own.sources) s.currencyCode}.difference({code}))
        cur: calc.liveTotal(own, range, now, currencyCode: cur),
    };
    rows.add((m, own, calc.summarize(own, range, now, currencyCode: code), others));
  }
  final total = Fraction.sum(rows.map((r) => r.$3.accrued));
  return [
    for (final (m, own, summary, others) in rows)
      MemberContribution(
        account: m,
        snapshot: own,
        month: summary,
        earned: summary.accrued,
        share: total.isZero ? 0 : (summary.accrued.toDouble() / total.toDouble()).clamp(0, 1),
        otherCurrencies: others,
      ),
  ];
});
