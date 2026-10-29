import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../core/date_time/local_date.dart';
import '../../core/errors/app_exception.dart';
import '../../database/app_database.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/income_source.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/services/validators.dart';
import '../local/audit_writer.dart';
import '../local/mappers.dart';

class LocalIncomeSourceRepository implements IncomeSourceRepository {
  LocalIncomeSourceRepository(this.db, this.clock, this.ids) : audit = AuditWriter(db, clock, ids);

  final AppDatabase db;
  final Clock clock;
  final IdGenerator ids;
  final AuditWriter audit;

  @override
  Stream<List<IncomeSource>> watchSources() => (db.select(db.incomeSources)
        ..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.createdAt)]))
      .watch()
      .map((rows) => rows.map((r) => r.toDomain()).toList());

  @override
  Future<List<IncomeSource>> sources() async =>
      (await db.select(db.incomeSources).get()).map((r) => r.toDomain()).toList();

  @override
  Future<IncomeSource?> source(String id) async =>
      (await (db.select(db.incomeSources)..where((t) => t.id.equals(id))).getSingleOrNull())?.toDomain();

  Future<IncomeSourceRow> _row(String id) async {
    final row = await (db.select(db.incomeSources)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) throw const NotFoundException('Income source not found');
    return row;
  }

  @override
  Future<void> createSource(IncomeSource source, {RateRevision? initialRate}) async {
    Validators.source(source);
    if (initialRate != null) Validators.revision(initialRate, source);
    await db.transaction(() async {
      final maxOrder = await (db.selectOnly(db.incomeSources)..addColumns([db.incomeSources.sortOrder.max()]))
          .map((r) => r.read(db.incomeSources.sortOrder.max()))
          .getSingleOrNull();
      final row = sourceToRow(source.copyWith(sortOrder: (maxOrder ?? -1) + 1));
      await db.into(db.incomeSources).insert(row);
      if (initialRate != null) await db.into(db.rateRevisions).insert(revisionToRow(initialRate));
      await audit.log(
        entityType: 'source',
        entityId: source.id,
        action: 'create',
        summary: 'Added ${source.kind.label.toLowerCase()} "${source.name}"',
        after: row.toJson(),
      );
    });
  }

  @override
  Future<void> updateSource(IncomeSource source) async {
    Validators.source(source);
    await db.transaction(() async {
      final before = await _row(source.id);
      final after = sourceToRow(source.copyWith(updatedAt: clock.now()));
      await db.update(db.incomeSources).replace(after);
      await audit.log(
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
        await db.update(db.incomeSources).replace(sourceToRow(updated));
        await audit.log(
          entityType: 'source',
          entityId: id,
          action: 'archive',
          summary: 'Archived "${s.name}"',
          before: before.toJson(),
          after: sourceToRow(updated).toJson(),
        );
      });

  @override
  Future<void> restoreSource(String id) => db.transaction(() async {
        final s = (await _row(id)).toDomain();
        final status = s.endDate != null && s.endDate!.isBefore(LocalDate.fromDateTime(clock.now()))
            ? SourceStatus.ended
            : SourceStatus.active;
        await db.update(db.incomeSources).replace(sourceToRow(s.copyWith(status: status, updatedAt: clock.now())));
        await audit.log(entityType: 'source', entityId: id, action: 'restore', summary: 'Restored "${s.name}"');
      });

  @override
  Future<void> pauseSource(String id, LocalDate from) => db.transaction(() async {
        final s = (await _row(id)).toDomain();
        final open = await (db.select(db.sourcePauses)
              ..where((t) => t.sourceId.equals(id) & t.endExclusive.isNull()))
            .get();
        if (open.isNotEmpty) throw const ValidationException('This source is already paused');
        await db.into(db.sourcePauses).insert(SourcePauseRow(id: ids.newId(), sourceId: id, start: from.toIso()));
        await db.update(db.incomeSources).replace(sourceToRow(s.copyWith(status: SourceStatus.paused, updatedAt: clock.now())));
        await audit.log(entityType: 'source', entityId: id, action: 'pause', summary: 'Paused "${s.name}" from $from');
      });

  @override
  Future<void> resumeSource(String id, LocalDate on) => db.transaction(() async {
        final s = (await _row(id)).toDomain();
        final open = await (db.select(db.sourcePauses)
              ..where((t) => t.sourceId.equals(id) & t.endExclusive.isNull()))
            .get();
        for (final p in open) {
          final start = LocalDate.parse(p.start);
          await (db.update(db.sourcePauses)..where((t) => t.id.equals(p.id)))
              .write(SourcePausesCompanion(endExclusive: Value(on.max(start).toIso())));
        }
        await db.update(db.incomeSources).replace(sourceToRow(s.copyWith(status: SourceStatus.active, updatedAt: clock.now())));
        await audit.log(entityType: 'source', entityId: id, action: 'resume', summary: 'Resumed "${s.name}" on $on');
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
        await (db.delete(db.ledgerEntries)..where((t) => t.sourceId.equals(id))).go();
        await (db.delete(db.compensationItems)..where((t) => t.sourceId.equals(id))).go();
        await (db.delete(db.monthlyRecords)..where((t) => t.sourceId.equals(id))).go();
        await (db.delete(db.calendarEvents)..where((t) => t.sourceId.equals(id))).go();
        await (db.delete(db.rateRevisions)..where((t) => t.sourceId.equals(id))).go();
        await (db.delete(db.sourcePauses)..where((t) => t.sourceId.equals(id))).go();
        await (db.delete(db.dayOverrides)..where((t) => t.sourceId.equals(id))).go();
        await (db.delete(db.incomeSources)..where((t) => t.id.equals(id))).go();
        await audit.log(
          entityType: 'source',
          entityId: id,
          action: 'delete',
          summary: 'Deleted unused source "${row.name}"',
          before: row.toJson(),
        );
      });

  @override
  Stream<List<RateRevision>> watchRevisions(String sourceId) => (db.select(db.rateRevisions)
        ..where((t) => t.sourceId.equals(sourceId))
        ..orderBy([(t) => OrderingTerm.desc(t.effectiveFrom), (t) => OrderingTerm.desc(t.createdAt)]))
      .watch()
      .map((rows) => rows.map((r) => r.toDomain()).toList());

  @override
  Future<void> addRevision(RateRevision revision) => db.transaction(() async {
        final s = (await _row(revision.sourceId)).toDomain();
        Validators.revision(revision, s);
        final row = revisionToRow(revision);
        await db.into(db.rateRevisions).insert(row);
        await audit.log(
          entityType: 'revision',
          entityId: revision.id,
          action: 'create',
          summary: '${revision.changeType.label} for "${s.name}" from ${revision.effectiveFrom}',
          after: row.toJson(),
        );
      });

  @override
  Future<void> updateRevision(RateRevision revision) => db.transaction(() async {
        final s = (await _row(revision.sourceId)).toDomain();
        Validators.revision(revision, s);
        final before = await (db.select(db.rateRevisions)..where((t) => t.id.equals(revision.id))).getSingle();
        final row = revisionToRow(revision);
        await db.update(db.rateRevisions).replace(row);
        await audit.log(
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
        final before = await (db.select(db.rateRevisions)..where((t) => t.id.equals(id))).getSingle();
        final siblings = await (db.select(db.rateRevisions)..where((t) => t.sourceId.equals(before.sourceId))).get();
        if (siblings.length <= 1) {
          throw const ValidationException('A source needs at least one rate. Edit it instead.');
        }
        await (db.delete(db.rateRevisions)..where((t) => t.id.equals(id))).go();
        await audit.log(
          entityType: 'revision',
          entityId: id,
          action: 'delete',
          summary: 'Removed rate change effective ${before.effectiveFrom}',
          before: before.toJson(),
        );
      });

  @override
  Stream<List<DayOverride>> watchOverrides() => (db.select(db.dayOverrides)
        ..orderBy([(t) => OrderingTerm.asc(t.date)]))
      .watch()
      .map((rows) => rows.map((r) => r.toDomain()).toList());

  @override
  Future<void> addOverride(DayOverride o) => db.transaction(() async {
        await db.into(db.dayOverrides).insert(overrideToRow(o));
        await audit.log(
          entityType: 'override',
          entityId: o.id,
          action: 'create',
          summary: '${o.type.label} on ${o.date}',
          after: overrideToRow(o).toJson(),
        );
      });

  @override
  Future<void> deleteOverride(String id) => db.transaction(() async {
        final before = await (db.select(db.dayOverrides)..where((t) => t.id.equals(id))).getSingle();
        await (db.delete(db.dayOverrides)..where((t) => t.id.equals(id))).go();
        await audit.log(
          entityType: 'override',
          entityId: id,
          action: 'delete',
          summary: 'Removed ${before.type} on ${before.date}',
          before: before.toJson(),
        );
      });

  @override
  Stream<List<SourcePause>> watchPauses(String sourceId) => (db.select(db.sourcePauses)
        ..where((t) => t.sourceId.equals(sourceId))
        ..orderBy([(t) => OrderingTerm.desc(t.start)]))
      .watch()
      .map((rows) => rows.map((r) => r.toDomain()).toList());
}
