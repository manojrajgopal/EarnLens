import '../../core/date_time/local_date.dart';
import '../models/enums.dart';
import '../models/income_source.dart';
import '../models/records.dart';
import 'source_rules.dart';

/// Immutable view of the persisted financial data of one or more accounts,
/// used by the calculators.
class EarningsSnapshot {
  EarningsSnapshot({
    required List<IncomeSource> sources,
    required this.revisions,
    this.pauses = const [],
    this.overrides = const [],
    this.items = const [],
    this.monthlyRecords = const [],
    this.ledger = const [],
  })  : sources = List.unmodifiable(sources),
        rules = {
          for (final s in sources)
            s.id: SourceRules(source: s, revisions: revisions, pauses: pauses, overrides: overrides),
        } {
    for (final r in monthlyRecords) {
      _records['${r.sourceId}|${r.month.toIso()}'] = r;
    }
  }

  static final empty = EarningsSnapshot(sources: const [], revisions: const []);

  final List<IncomeSource> sources;
  final List<RateRevision> revisions;
  final List<SourcePause> pauses;
  final List<DayOverride> overrides;
  final Map<String, SourceRules> rules;
  final List<CompensationItem> items;
  final List<MonthlyRecord> monthlyRecords;
  final List<LedgerEntry> ledger;
  final Map<String, MonthlyRecord> _records = {};

  IncomeSource? source(String id) => rules[id]?.source;

  /// Accounts that own at least one source in this snapshot.
  Set<String> get accountIds => {for (final s in sources) s.accountId};

  /// Only the records owned by [accountIds]. Used for the member-wise
  /// breakdown of a combined account: the same records, filtered, never
  /// copied into the database.
  EarningsSnapshot subset(Set<String> accountIds) {
    bool keep(String accountId) => accountIds.contains(accountId);
    return EarningsSnapshot(
      sources: sources.where((s) => keep(s.accountId)).toList(),
      revisions: revisions.where((r) => keep(r.accountId)).toList(),
      pauses: pauses.where((p) => keep(p.accountId)).toList(),
      overrides: overrides.where((o) => keep(o.accountId)).toList(),
      items: items.where((i) => keep(i.accountId)).toList(),
      monthlyRecords: monthlyRecords.where((r) => keep(r.accountId)).toList(),
      ledger: ledger.where((e) => keep(e.accountId)).toList(),
    );
  }

  MonthlyRecord? record(String sourceId, YearMonth m) => _records['$sourceId|${m.toIso()}'];

  Iterable<CompensationItem> itemsFor(String sourceId) =>
      items.where((i) => i.sourceId == sourceId && !i.cancelled);

  Iterable<LedgerEntry> ledgerFor(String sourceId) =>
      ledger.where((e) => e.sourceId == sourceId && e.status.counts);

  /// The default monthly estimate of a variable source on [d].
  int? defaultEstimate(String sourceId, LocalDate d) {
    final rev = rules[sourceId]?.revisionOn(d);
    if (rev == null) return null;
    return switch (rev.period) {
      RatePeriod.month => rev.amountMinor,
      RatePeriod.year => rev.amountMinor ~/ 12,
      RatePeriod.week => rev.amountMinor * LocalDate.daysInMonth(d.year, d.month) ~/ 7,
      RatePeriod.day => rev.amountMinor * LocalDate.daysInMonth(d.year, d.month),
      RatePeriod.hour => null,
    };
  }

  /// Expected amount for a variable source in month [m]: revised estimate,
  /// else original estimate, else the source's default estimate.
  int? variableExpected(String sourceId, YearMonth m) =>
      record(sourceId, m)?.baselineEstimateMinor ?? defaultEstimate(sourceId, m.firstDay);

  /// Earned ledger entries for [sourceId] with dates in [range].
  int earnedEntries(String sourceId, DateRange range, {LocalDate? upTo}) {
    var sum = 0;
    for (final e in ledgerFor(sourceId)) {
      if (e.type != LedgerType.earned) continue;
      if (!range.contains(e.date)) continue;
      if (upTo != null && e.date.isAfter(upTo)) continue;
      sum += e.amountMinor;
    }
    return sum;
  }

  /// Actual earnings of a variable source in month [m], or null when unknown.
  /// A recorded monthly total wins; detailed entries are then informational
  /// and are never added on top (prevents double counting).
  int? variableActual(String sourceId, YearMonth m, {LocalDate? upTo}) {
    final rec = record(sourceId, m);
    if (rec?.actualMinor != null) return rec!.actualMinor;
    final range = DateRange.month(m);
    final hasEntries = ledgerFor(sourceId).any((e) =>
        e.type == LedgerType.earned && range.contains(e.date) && (upTo == null || !e.date.isAfter(upTo)));
    return hasEntries ? earnedEntries(sourceId, range, upTo: upTo) : null;
  }
}
