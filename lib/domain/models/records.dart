import '../../core/date_time/local_date.dart';
import 'enums.dart';

/// Bonus, benefit, allowance, reimbursement or one-time income.
///
/// Expected and actual values are kept side by side; receiving cash is
/// recorded separately as a [LedgerEntry] linked through [id].
class CompensationItem {
  const CompensationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.currencyCode,
    required this.createdAt,
    required this.updatedAt,
    this.sourceId,
    this.expectedMinor,
    this.expectedDate,
    this.actualMinor,
    this.earnedDate,
    this.recurrence = Recurrence.none,
    this.nonCash = false,
    this.countsAsEarnings = true,
    this.includeInForecast = true,
    this.taxNote,
    this.notes,
    this.cancelled = false,
  });

  final String id;
  final String? sourceId;
  final CompensationType type;
  final String title;
  final String currencyCode;
  final int? expectedMinor;
  final LocalDate? expectedDate;
  final int? actualMinor;
  final LocalDate? earnedDate;
  final Recurrence recurrence;

  /// Non-cash benefits (insurance, meal cards) are never treated as cash received.
  final bool nonCash;
  final bool countsAsEarnings;
  final bool includeInForecast;
  final String? taxNote;
  final String? notes;
  final bool cancelled;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isEarned => actualMinor != null && earnedDate != null && !cancelled;

  /// Date used for expected-income views.
  LocalDate? get planningDate => expectedDate ?? earnedDate;
}

/// Monthly estimate vs actual for a variable income source.
///
/// The original estimate is never overwritten: later changes go to
/// [revisedEstimateMinor], and the actual figure is stored separately.
class MonthlyRecord {
  const MonthlyRecord({
    required this.id,
    required this.sourceId,
    required this.month,
    required this.updatedAt,
    this.originalEstimateMinor,
    this.revisedEstimateMinor,
    this.actualMinor,
    this.finalized = false,
    this.finalizedAt,
    this.notes,
  });

  final String id;
  final String sourceId;
  final YearMonth month;
  final int? originalEstimateMinor;
  final int? revisedEstimateMinor;
  final int? actualMinor;
  final bool finalized;
  final DateTime? finalizedAt;
  final String? notes;
  final DateTime updatedAt;

  int? get baselineEstimateMinor => revisedEstimateMinor ?? originalEstimateMinor;
}

/// A ledger transaction. Only [LedgerType.earned] and [LedgerType.adjustment]
/// can change earnings; [LedgerType.received] only changes cash received, so
/// recording a salary payment can never double count accrued salary.
class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.sourceId,
    required this.type,
    required this.amountMinor,
    required this.currencyCode,
    required this.periodMonth,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.itemId,
    this.status = LedgerStatus.completed,
    this.dedupeKey,
    this.notes,
  });

  final String id;
  final String sourceId;
  final String? itemId;
  final LedgerType type;

  /// Positive for all types except [LedgerType.adjustment], which is signed.
  final int amountMinor;
  final String currencyCode;

  /// The earning period this entry belongs to (e.g. October salary paid in November).
  final YearMonth periodMonth;

  /// Earned date for earnings; payment date for receipts.
  final LocalDate date;
  final LedgerStatus status;

  /// Unique key preventing duplicate payments for the same period.
  final String? dedupeKey;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.type,
    required this.createdAt,
    this.sourceId,
    this.amountMinor,
    this.notes,
    this.remind = false,
    this.cancelled = false,
  });

  final String id;
  final String title;
  final LocalDate date;
  final CalendarEventType type;
  final String? sourceId;
  final int? amountMinor;
  final String? notes;
  final bool remind;
  final bool cancelled;
  final DateTime createdAt;
}

class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.summary,
    required this.at,
    this.beforeJson,
    this.afterJson,
  });

  final String id;
  final String entityType;
  final String entityId;
  final String action;
  final String summary;
  final String? beforeJson;
  final String? afterJson;
  final DateTime at;
}
