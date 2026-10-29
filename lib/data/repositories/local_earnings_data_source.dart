import 'dart:async';

import 'package:drift/drift.dart';

import '../../database/app_database.dart';
import '../../domain/calculation/earnings_snapshot.dart';
import '../../domain/repositories/repositories.dart';
import '../local/mappers.dart';

/// Loads every financial table into an [EarningsSnapshot] and reloads it
/// whenever one of them changes. Totals are always derived from these
/// authoritative records — there is no cached snapshot to drift out of date.
class LocalEarningsDataSource implements EarningsDataSource {
  LocalEarningsDataSource(this.db);
  final AppDatabase db;

  List<TableInfo> get _tables => [
        db.incomeSources,
        db.rateRevisions,
        db.sourcePauses,
        db.dayOverrides,
        db.compensationItems,
        db.monthlyRecords,
        db.ledgerEntries,
      ];

  @override
  Future<EarningsSnapshot> loadSnapshot() async {
    final sources = await db.select(db.incomeSources).get();
    final revisions = await db.select(db.rateRevisions).get();
    final pauses = await db.select(db.sourcePauses).get();
    final overrides = await db.select(db.dayOverrides).get();
    final items = await db.select(db.compensationItems).get();
    final records = await db.select(db.monthlyRecords).get();
    final ledger = await db.select(db.ledgerEntries).get();
    return EarningsSnapshot(
      sources: sources.map((r) => r.toDomain()).toList(),
      revisions: revisions.map((r) => r.toDomain()).toList(),
      pauses: pauses.map((r) => r.toDomain()).toList(),
      overrides: overrides.map((r) => r.toDomain()).toList(),
      items: items.map((r) => r.toDomain()).toList(),
      monthlyRecords: records.map((r) => r.toDomain()).toList(),
      ledger: ledger.map((r) => r.toDomain()).toList(),
    );
  }

  /// Emits a fresh snapshot on listen and after every change. Bursts of
  /// updates (imports, restores) are coalesced into a single reload.
  @override
  Stream<EarningsSnapshot> watchSnapshot() {
    late final StreamController<EarningsSnapshot> controller;
    StreamSubscription<Set<TableUpdate>>? updates;
    var loading = false;
    var dirty = false;

    Future<void> reload() async {
      if (loading) {
        dirty = true;
        return;
      }
      loading = true;
      try {
        do {
          dirty = false;
          final snap = await loadSnapshot();
          if (!controller.isClosed) controller.add(snap);
        } while (dirty && !controller.isClosed);
      } on Object catch (e, s) {
        if (!controller.isClosed) controller.addError(e, s);
      } finally {
        loading = false;
      }
    }

    controller = StreamController<EarningsSnapshot>(
      onListen: () {
        updates = db.tableUpdates(TableUpdateQuery.onAllTables(_tables)).listen((_) => reload());
        reload();
      },
      onCancel: () => updates?.cancel(),
    );
    return controller.stream;
  }
}
