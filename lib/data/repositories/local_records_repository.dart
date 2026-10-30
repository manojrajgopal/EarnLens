import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../core/date_time/local_date.dart';
import '../../core/errors/app_exception.dart';
import '../../database/app_database.dart';
import '../../domain/models/account.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/records.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/services/validators.dart';
import '../local/audit_writer.dart';
import '../local/mappers.dart';

/// Compensation items, monthly records, ledger entries, calendar events and
/// the audit trail of the accounts in [scope].
///
/// Follows the same rules as `LocalIncomeSourceRepository`: reads are limited
/// to visible accounts, writes go to the writable account only, existing rows
/// must already belong to it, and combined scopes are read-only.
class LocalRecordsRepository implements RecordsRepository {
  LocalRecordsRepository(this.db, this.clock, this.ids, this.scope) : audit = AuditWriter(db, clock, ids);

  final AppDatabase db;
  final Clock clock;
  final IdGenerator ids;
  final AccountScope scope;
  final AuditWriter audit;

  String get _owner => scope.writableAccountId ?? (throw const ReadOnlyViewException());

  /// Throws unless the existing row (if any) belongs to [owner].
  void _checkOwner(String? rowAccountId, String owner) {
    if (rowAccountId != null && rowAccountId != owner) throw const AccountOwnershipException();
  }

  Future<void> _checkSource(String? sourceId, String owner) async {
    if (sourceId == null) return;
    final row = await (db.select(db.incomeSources)..where((t) => t.id.equals(sourceId))).getSingleOrNull();
    if (row == null) throw const NotFoundException('Income source not found');
    _checkOwner(row.accountId, owner);
  }

  // ---- Compensation items -------------------------------------------------

  @override
  Future<void> saveItem(CompensationItem item) => db.transaction(() async {
        final owner = _owner;
        Validators.item(item);
        final before = await (db.select(db.compensationItems)..where((t) => t.id.equals(item.id))).getSingleOrNull();
        _checkOwner(before?.accountId, owner);
        await _checkSource(item.sourceId, owner);
        final row = itemToRow(item, accountId: owner);
        await db.into(db.compensationItems).insertOnConflictUpdate(row);
        await audit.log(
          accountId: owner,
          entityType: 'item',
          entityId: item.id,
          action: before == null ? 'create' : 'update',
          summary: '${before == null ? 'Added' : 'Edited'} ${item.type.label.toLowerCase()} "${item.title}"',
          before: before?.toJson(),
          after: row.toJson(),
        );
      });

  @override
  Future<void> cancelItem(String id) => db.transaction(() async {
        final owner = _owner;
        final before = await (db.select(db.compensationItems)..where((t) => t.id.equals(id))).getSingleOrNull();
        if (before == null) throw const NotFoundException('Item not found');
        _checkOwner(before.accountId, owner);
        await (db.update(db.compensationItems)..where((t) => t.id.equals(id))).write(
          CompensationItemsCompanion(cancelled: const Value(true), updatedAt: Value(ts(clock.now()))),
        );
        await audit.log(
          accountId: owner,
          entityType: 'item',
          entityId: id,
          action: 'cancel',
          summary: 'Cancelled "${before.title}"',
          before: before.toJson(),
        );
      });

  // ---- Monthly records (variable income) ---------------------------------

  /// The month's record of a source owned by [owner].
  Future<MonthlyRecordRow?> _record(String sourceId, YearMonth month, String owner) async {
    await _checkSource(sourceId, owner);
    return (db.select(db.monthlyRecords)..where((t) => t.sourceId.equals(sourceId) & t.month.equals(month.toIso())))
        .getSingleOrNull();
  }

  @override
  Future<void> saveMonthlyRecord(MonthlyRecord record) => db.transaction(() async {
        final owner = _owner;
        Validators.monthly(record);
        final before = await _record(record.sourceId, record.month, owner);
        if (before != null && before.finalized && before.actualMinor != record.actualMinor) {
          throw const ValidationException('This month is finalised. Reopen it to change the actual amount.');
        }
        // The caller passes the desired current estimate. The first estimate
        // ever entered is kept as the original; later changes become the
        // revised estimate, so the original is never overwritten.
        final desired = record.revisedEstimateMinor ?? record.originalEstimateMinor;
        var original = before?.originalEstimateMinor;
        var revised = before?.revisedEstimateMinor;
        if (desired != null) {
          if (original == null) {
            original = desired;
          } else if (desired != (revised ?? original)) {
            revised = desired;
          }
        }
        final row = recordToRow(
          MonthlyRecord(
            id: before?.id ?? record.id,
            sourceId: record.sourceId,
            month: record.month,
            originalEstimateMinor: original,
            revisedEstimateMinor: revised,
            actualMinor: record.actualMinor,
            finalized: before?.finalized ?? record.finalized,
            finalizedAt: before?.finalizedAt == null ? record.finalizedAt : fromTs(before!.finalizedAt!),
            notes: record.notes,
            updatedAt: clock.now(),
          ),
          accountId: owner,
        );
        await db.into(db.monthlyRecords).insertOnConflictUpdate(row);
        await audit.log(
          accountId: owner,
          entityType: 'monthly',
          entityId: row.id,
          action: before == null ? 'create' : 'update',
          summary: 'Updated ${record.month} figures',
          before: before?.toJson(),
          after: row.toJson(),
        );
      });

  @override
  Future<void> finalizeMonth(String sourceId, YearMonth month, int actualMinor) => db.transaction(() async {
        final owner = _owner;
        Validators.amount(actualMinor, field: 'actual');
        final before = await _record(sourceId, month, owner);
        final row = MonthlyRecordRow(
          id: before?.id ?? ids.newId(),
          accountId: owner,
          sourceId: sourceId,
          month: month.toIso(),
          originalEstimateMinor: before?.originalEstimateMinor,
          revisedEstimateMinor: before?.revisedEstimateMinor,
          actualMinor: actualMinor,
          finalized: true,
          finalizedAt: ts(clock.now()),
          notes: before?.notes,
          updatedAt: ts(clock.now()),
        );
        await db.into(db.monthlyRecords).insertOnConflictUpdate(row);
        await audit.log(
          accountId: owner,
          entityType: 'monthly',
          entityId: row.id,
          action: 'finalize',
          summary: 'Finalised $month with an actual of $actualMinor (minor units)',
          before: before?.toJson(),
          after: row.toJson(),
        );
      });

  @override
  Future<void> reopenMonth(String sourceId, YearMonth month, String reason) => db.transaction(() async {
        final owner = _owner;
        final before = await _record(sourceId, month, owner);
        if (before == null || !before.finalized) return;
        await (db.update(db.monthlyRecords)..where((t) => t.id.equals(before.id))).write(
          MonthlyRecordsCompanion(
            finalized: const Value(false),
            finalizedAt: const Value(null),
            updatedAt: Value(ts(clock.now())),
          ),
        );
        await audit.log(
          accountId: owner,
          entityType: 'monthly',
          entityId: before.id,
          action: 'reopen',
          summary: 'Reopened $month${reason.isEmpty ? '' : ': $reason'}',
          before: before.toJson(),
        );
      });

  // ---- Ledger -------------------------------------------------------------

  /// Source ids are unique per account, so the key never collides across
  /// accounts.
  static String dedupeKeyFor(LedgerEntry e) =>
      '${e.sourceId}|${e.itemId ?? ''}|${e.type.name}|${e.periodMonth.toIso()}|${e.date.toIso()}|${e.amountMinor}';

  Future<void> _checkLedgerLinks(LedgerEntry entry, String owner) async {
    await _checkSource(entry.sourceId, owner);
    if (entry.itemId != null) {
      final item =
          await (db.select(db.compensationItems)..where((t) => t.id.equals(entry.itemId!))).getSingleOrNull();
      if (item == null) throw const NotFoundException('Item not found');
      _checkOwner(item.accountId, owner);
    }
  }

  Future<LedgerEntryRow> _ledger(String id, String owner) async {
    final row = await (db.select(db.ledgerEntries)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) throw const NotFoundException('Entry not found');
    _checkOwner(row.accountId, owner);
    return row;
  }

  @override
  Future<void> addLedgerEntry(LedgerEntry entry, {bool allowDuplicate = false}) => db.transaction(() async {
        final owner = _owner;
        Validators.ledger(entry);
        await _checkLedgerLinks(entry, owner);
        final key = allowDuplicate ? null : (entry.dedupeKey ?? dedupeKeyFor(entry));
        if (key != null) {
          final existing =
              await (db.select(db.ledgerEntries)..where((t) => t.dedupeKey.equals(key))).getSingleOrNull();
          if (existing != null) {
            throw const DuplicateEntryException(
                'An identical entry already exists for this period. Add it anyway only if it is a separate payment.');
          }
        }
        final row = ledgerToRow(
          LedgerEntry(
            id: entry.id,
            sourceId: entry.sourceId,
            itemId: entry.itemId,
            type: entry.type,
            amountMinor: entry.amountMinor,
            currencyCode: entry.currencyCode,
            periodMonth: entry.periodMonth,
            date: entry.date,
            status: entry.status,
            dedupeKey: key,
            notes: entry.notes,
            createdAt: entry.createdAt,
            updatedAt: entry.updatedAt,
          ),
          accountId: owner,
        );
        await db.into(db.ledgerEntries).insert(row);
        await audit.log(
          accountId: owner,
          entityType: 'ledger',
          entityId: entry.id,
          action: 'create',
          summary: '${entry.type.label} for ${entry.periodMonth}',
          after: row.toJson(),
        );
      });

  @override
  Future<void> updateLedgerEntry(LedgerEntry entry) => db.transaction(() async {
        final owner = _owner;
        Validators.ledger(entry);
        final before = await _ledger(entry.id, owner);
        await _checkLedgerLinks(entry, owner);
        final row = ledgerToRow(entry, accountId: owner).copyWith(
          dedupeKey: Value(before.dedupeKey == null ? null : dedupeKeyFor(entry)),
          updatedAt: ts(clock.now()),
        );
        await db.update(db.ledgerEntries).replace(row);
        await audit.log(
          accountId: owner,
          entityType: 'ledger',
          entityId: entry.id,
          action: 'update',
          summary: 'Corrected ${entry.type.label.toLowerCase()} for ${entry.periodMonth}',
          before: before.toJson(),
          after: row.toJson(),
        );
      });

  @override
  Future<void> setLedgerStatus(String id, LedgerStatus status) => db.transaction(() async {
        final owner = _owner;
        final before = await _ledger(id, owner);
        await (db.update(db.ledgerEntries)..where((t) => t.id.equals(id))).write(LedgerEntriesCompanion(
          status: Value(status.name),
          // Cancelled/reversed entries release their duplicate-guard key.
          dedupeKey: status.counts || status == LedgerStatus.pending ? Value(before.dedupeKey) : const Value(null),
          updatedAt: Value(ts(clock.now())),
        ));
        await audit.log(
          accountId: owner,
          entityType: 'ledger',
          entityId: id,
          action: 'status',
          summary: 'Marked entry ${status.label.toLowerCase()}',
          before: before.toJson(),
        );
      });

  // ---- Calendar -----------------------------------------------------------

  @override
  Stream<List<CalendarEvent>> watchEvents() => (db.select(db.calendarEvents)
        ..where((t) => t.accountId.isIn(scope.visibleAccountIds))
        ..orderBy([(t) => OrderingTerm.asc(t.date)]))
      .watch()
      .map((rows) => rows.map((r) => r.toDomain()).toList());

  @override
  Future<void> saveEvent(CalendarEvent event) => db.transaction(() async {
        final owner = _owner;
        if (event.title.trim().isEmpty) throw const ValidationException('Title is required', field: 'title');
        if (event.amountMinor != null) Validators.amount(event.amountMinor!);
        final before = await (db.select(db.calendarEvents)..where((t) => t.id.equals(event.id))).getSingleOrNull();
        _checkOwner(before?.accountId, owner);
        await _checkSource(event.sourceId, owner);
        final row = eventToRow(event, accountId: owner);
        await db.into(db.calendarEvents).insertOnConflictUpdate(row);
        await audit.log(
          accountId: owner,
          entityType: 'event',
          entityId: event.id,
          action: before == null ? 'create' : 'update',
          summary: '${before == null ? 'Added' : 'Edited'} event "${event.title}" on ${event.date}',
          before: before?.toJson(),
          after: row.toJson(),
        );
      });

  @override
  Future<void> cancelEvent(String id) => db.transaction(() async {
        final owner = _owner;
        final before = await (db.select(db.calendarEvents)..where((t) => t.id.equals(id))).getSingleOrNull();
        if (before == null) throw const NotFoundException('Event not found');
        _checkOwner(before.accountId, owner);
        await (db.update(db.calendarEvents)..where((t) => t.id.equals(id)))
            .write(const CalendarEventsCompanion(cancelled: Value(true)));
        await audit.log(accountId: owner, entityType: 'event', entityId: id, action: 'cancel', summary: 'Cancelled event');
      });

  // ---- Audit --------------------------------------------------------------

  @override
  Stream<List<AuditEntry>> watchAudit({String? entityId, int limit = 200}) {
    final q = db.select(db.auditLog)
      ..where((t) => t.accountId.isIn(scope.visibleAccountIds))
      ..orderBy([(t) => OrderingTerm.desc(t.at)])
      ..limit(limit);
    if (entityId != null) q.where((t) => t.entityId.equals(entityId));
    return q.watch().map((rows) => rows.map((r) => r.toDomain()).toList());
  }
}
