import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../core/date_time/local_date.dart';
import '../../core/errors/app_exception.dart';
import '../../database/app_database.dart';
import '../../domain/models/account.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/income_source.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/services/validators.dart';
import '../local/audit_writer.dart';
import '../local/mappers.dart';

/// Income sources, rate revisions, pauses and holiday overrides of the
/// accounts in [scope].
///
/// * Reads only return rows whose `account_id` is visible in the scope.
/// * Writes always target [AccountScope.writableAccountId]; the owner on a
///   passed-in model is ignored. Updates and deletes first check that the
///   existing row belongs to that account, so a record of one account can
///   never be changed while another account is open.
/// * In a combined (read-only) scope every write throws
///   [ReadOnlyViewException].
class LocalIncomeSourceRepository implements IncomeSourceRepository {
  LocalIncomeSourceRepository(this.db, this.clock, this.ids, this.scope) : audit = AuditWriter(db, clock, ids);

  final AppDatabase db;
  final Clock clock;
  final IdGenerator ids;
  final AccountScope scope;
  final AuditWriter audit;

  String get _owner => scope.writableAccountId ?? (throw const ReadOnlyViewException());

  @override
  Stream<List<IncomeSource>> watchSources() => (db.select(db.incomeSources)
        ..where((t) => t.accountId.isIn(scope.visibleAccountIds))
        ..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.createdAt)]))
      .watch()
      .map((rows) => rows.map((r) => r.toDomain()).toList());

  @override
  Future<List<IncomeSource>> sources() async =>
      (await (db.select(db.incomeSources)..where((t) => t.accountId.isIn(scope.visibleAccountIds))).get())
          .map((r) => r.toDomain())
          .toList();

  @override
  Future<IncomeSource?> source(String id) async => (await (db.select(db.incomeSources)
            ..where((t) => t.id.equals(id) & t.accountId.isIn(scope.visibleAccountIds)))
          .getSingleOrNull())
      ?.toDomain();

  /// The source row, if it belongs to the writable account.
  Future<IncomeSourceRow> _row(String id) async {
    final owner = _owner;
    final row = await (db.select(db.incomeSources)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) throw const NotFoundException('Income source not found');
    if (row.accountId != owner) throw const AccountOwnershipException();
    return row;
  }

  @override
  Future<void> createSource(IncomeSource source, {RateRevision? initialRate}) async {
    Validators.source(source);
    if (initialRate != null) {
      Validators.revision(initialRate, source);
      if (initialRate.sourceId != source.id) throw const ValidationException('The starting rate belongs to another source');
    }
    final owner = _owner;
    await db.transaction(() async {
      await _requireAccount(owner);
      final maxOrder = await (db.selectOnly(db.incomeSources)
            ..addColumns([db.incomeSources.sortOrder.max()])
            ..where(db.incomeSources.accountId.equals(owner)))
          .map((r) => r.read(db.incomeSources.sortOrder.max()))
          .getSingleOrNull();
      final row = sourceToRow(source.copyWith(sortOrder: (maxOrder ?? -1) + 1), accountId: owner);
      await db.into(db.incomeSources).insert(row);
      if (initialRate != null) await db.into(db.rateRevisions).insert(revisionToRow(initialRate, accountId: owner));
      await audit.log(
        accountId: owner,
        entityType: 'source',
        entityId: source.id,
        action: 'create',
        summary: 'Added ${source.kind.label.toLowerCase()} "${source.name}"',
        after: row.toJson(),
      );
    });
  }

  Future<void> _requireAccount(String id) async {
    final exists = await (db.select(db.accounts)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (exists == null) throw const NotFoundException('Account not found');
  }

  @override
  Future<void> updateSource(IncomeSource source) async {
    Validators.source(source);
    await db.transaction(() async {
      final before = await _row(source.id);
      final after = sourceToRow(source.copyWith(updatedAt: clock.now()), accountId: before.accountId);
      await db.update(db.incomeSources).replace(after);
      await audit.log(
        accountId: before.accountId,
        entityType: 'source',
        entityId: source.id,
        action: 'update',
        summary: 'Edited "${source.name}"',
        before: before.toJson(),
        after: after.toJson(),
      );
    });
  }

  @override
  Future<void> archiveSource(String id, LocalDate endDate) => db.transaction(() async {
        final before = await _row(id);
        final s = before.toDomain();
        final updated = s.copyWith(
          status: SourceStatus.archived,
          endDate: s.endDate ?? endDate.max(s.startDate),
          updatedAt: clock.now(),
        );
        final row = sourceToRow(updated, accountId: before.accountId);
        await db.update(db.incomeSources).replace(row);
        await audit.log(
          accountId: before.accountId,
          entityType: 'source',
          entityId: id,
          action: 'archive',
          summary: 'Archived "${s.name}"',
          before: before.toJson(),
          after: row.toJson(),
        );
      });

  @override
  Future<void> restoreSource(String id) => db.transaction(() async {
        final row = await _row(id);
        final s = row.toDomain();
        final status = s.endDate != null && s.endDate!.isBefore(LocalDate.fromDateTime(clock.now()))
            ? SourceStatus.ended
            : SourceStatus.active;
        await db
            .update(db.incomeSources)
            .replace(sourceToRow(s.copyWith(status: status, updatedAt: clock.now()), accountId: row.accountId));
        await audit.log(
            accountId: row.accountId, entityType: 'source', entityId: id, action: 'restore', summary: 'Restored "${s.name}"');
      });

  @override
  Future<void> pauseSource(String id, LocalDate from) => db.transaction(() async {
        final row = await _row(id);
        final s = row.toDomain();
        final open = await (db.select(db.sourcePauses)
              ..where((t) => t.sourceId.equals(id) & t.endExclusive.isNull()))
            .get();
        if (open.isNotEmpty) throw const ValidationException('This source is already paused');
        await db
            .into(db.sourcePauses)
            .insert(SourcePauseRow(id: ids.newId(), accountId: row.accountId, sourceId: id, start: from.toIso()));
        await db.update(db.incomeSources).replace(
            sourceToRow(s.copyWith(status: SourceStatus.paused, updatedAt: clock.now()), accountId: row.accountId));
        await audit.log(
            accountId: row.accountId,
            entityType: 'source',
            entityId: id,
            action: 'pause',
            summary: 'Paused "${s.name}" from $from');
      });

  @override
  Future<void> resumeSource(String id, LocalDate on) => db.transaction(() async {
        final row = await _row(id);
        final s = row.toDomain();
        final open = await (db.select(db.sourcePauses)
              ..where((t) => t.sourceId.equals(id) & t.endExclusive.isNull()))
            .get();
        for (final p in open) {
          final start = LocalDate.parse(p.start);
          await (db.update(db.sourcePauses)..where((t) => t.id.equals(p.id)))
              .write(SourcePausesCompanion(endExclusive: Value(on.max(start).toIso())));
        }
        await db.update(db.incomeSources).replace(
            sourceToRow(s.copyWith(status: SourceStatus.active, updatedAt: clock.now()), accountId: row.accountId));
        await audit.log(
            accountId: row.accountId,
            entityType: 'source',
            entityId: id,
            action: 'resume',
            summary: 'Resumed "${s.name}" on $on');
      });

  @override
  Future<void> deleteSourceIfUnused(String id) => db.transaction(() async {
        final row = await _row(id);
        Future<int> count(TableInfo t, Expression<bool> Function() where) async {
          final q = db.selectOnly(t)..addColumns([countAll()])..where(where());
          return (await q.map((r) => r.read(countAll())).getSingle()) ?? 0;
        }

        final history = await count(db.ledgerEntries, () => db.ledgerEntries.sourceId.equals(id)) +
            await count(db.compensationItems, () => db.compensationItems.sourceId.equals(id)) +
            await count(db.monthlyRecords, () => db.monthlyRecords.sourceId.equals(id));
        if (history > 0 && !row.isSample) {
          throw const ProtectedHistoryException(
              'This source has payments or records. Archive it instead so your history is kept.');
        }
        // Children carry the same account id as the source (enforced by
        // database triggers), so only this account's records are removed.
        await (db.delete(db.ledgerEntries)..where((t) => t.sourceId.equals(id))).go();
        await (db.delete(db.compensationItems)..where((t) => t.sourceId.equals(id))).go();
        await (db.delete(db.monthlyRecords)..where((t) => t.sourceId.equals(id))).go();
        await (db.delete(db.calendarEvents)..where((t) => t.sourceId.equals(id))).go();
        await (db.delete(db.rateRevisions)..where((t) => t.sourceId.equals(id))).go();
        await (db.delete(db.sourcePauses)..where((t) => t.sourceId.equals(id))).go();
        await (db.delete(db.dayOverrides)..where((t) => t.sourceId.equals(id))).go();
        await (db.delete(db.incomeSources)..where((t) => t.id.equals(id))).go();
        await audit.log(
          accountId: row.accountId,
          entityType: 'source',
          entityId: id,
          action: 'delete',
          summary: 'Deleted unused source "${row.name}"',
          before: row.toJson(),
        );
      });

  @override
  Stream<List<RateRevision>> watchRevisions(String sourceId) => (db.select(db.rateRevisions)
        ..where((t) => t.sourceId.equals(sourceId) & t.accountId.isIn(scope.visibleAccountIds))
        ..orderBy([(t) => OrderingTerm.desc(t.effectiveFrom), (t) => OrderingTerm.desc(t.createdAt)]))
      .watch()
      .map((rows) => rows.map((r) => r.toDomain()).toList());

  Future<RateRevisionRow> _revision(String id) async {
    final owner = _owner;
    final row = await (db.select(db.rateRevisions)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) throw const NotFoundException('Rate change not found');
    if (row.accountId != owner) throw const AccountOwnershipException();
    return row;
  }

  @override
  Future<void> addRevision(RateRevision revision) => db.transaction(() async {
        final source = await _row(revision.sourceId);
        final s = source.toDomain();
        Validators.revision(revision, s);
        final row = revisionToRow(revision, accountId: source.accountId);
        await db.into(db.rateRevisions).insert(row);
        await audit.log(
          accountId: source.accountId,
          entityType: 'revision',
          entityId: revision.id,
          action: 'create',
          summary: '${revision.changeType.label} for "${s.name}" from ${revision.effectiveFrom}',
          after: row.toJson(),
        );
      });

  @override
  Future<void> updateRevision(RateRevision revision) => db.transaction(() async {
        final before = await _revision(revision.id);
        if (before.sourceId != revision.sourceId) throw const ValidationException('A rate change cannot move to another source');
        final source = await _row(revision.sourceId);
        final s = source.toDomain();
        Validators.revision(revision, s);
        final row = revisionToRow(revision, accountId: source.accountId);
        await db.update(db.rateRevisions).replace(row);
        await audit.log(
          accountId: source.accountId,
          entityType: 'revision',
          entityId: revision.id,
          action: 'update',
          summary: 'Corrected rate for "${s.name}" effective ${revision.effectiveFrom}',
          before: before.toJson(),
          after: row.toJson(),
        );
      });

  @override
  Future<void> deleteRevision(String id) => db.transaction(() async {
        final before = await _revision(id);
        final siblings = await (db.select(db.rateRevisions)..where((t) => t.sourceId.equals(before.sourceId))).get();
        if (siblings.length <= 1) {
          throw const ValidationException('A source needs at least one rate. Edit it instead.');
        }
        await (db.delete(db.rateRevisions)..where((t) => t.id.equals(id))).go();
        await audit.log(
          accountId: before.accountId,
          entityType: 'revision',
          entityId: id,
          action: 'delete',
          summary: 'Removed rate change effective ${before.effectiveFrom}',
          before: before.toJson(),
        );
      });

  @override
  Stream<List<DayOverride>> watchOverrides() => (db.select(db.dayOverrides)
        ..where((t) => t.accountId.isIn(scope.visibleAccountIds))
        ..orderBy([(t) => OrderingTerm.asc(t.date)]))
      .watch()
      .map((rows) => rows.map((r) => r.toDomain()).toList());

  @override
  Future<void> addOverride(DayOverride o) => db.transaction(() async {
        final owner = _owner;
        if (o.sourceId != null) await _row(o.sourceId!);
        final row = overrideToRow(o, accountId: owner);
        await db.into(db.dayOverrides).insert(row);
        await audit.log(
          accountId: owner,
          entityType: 'override',
          entityId: o.id,
          action: 'create',
          summary: '${o.type.label} on ${o.date}',
          after: row.toJson(),
        );
      });

  @override
  Future<void> deleteOverride(String id) => db.transaction(() async {
        final owner = _owner;
        final before = await (db.select(db.dayOverrides)..where((t) => t.id.equals(id))).getSingleOrNull();
        if (before == null) throw const NotFoundException('Holiday not found');
        if (before.accountId != owner) throw const AccountOwnershipException();
        await (db.delete(db.dayOverrides)..where((t) => t.id.equals(id))).go();
        await audit.log(
          accountId: owner,
          entityType: 'override',
          entityId: id,
          action: 'delete',
          summary: 'Removed ${before.type} on ${before.date}',
          before: before.toJson(),
        );
      });

  @override
  Stream<List<SourcePause>> watchPauses(String sourceId) => (db.select(db.sourcePauses)
        ..where((t) => t.sourceId.equals(sourceId) & t.accountId.isIn(scope.visibleAccountIds))
        ..orderBy([(t) => OrderingTerm.desc(t.start)]))
      .watch()
      .map((rows) => rows.map((r) => r.toDomain()).toList());
}
