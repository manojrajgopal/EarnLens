import 'dart:async';

import 'package:drift/drift.dart';

import '../../database/app_database.dart';
import '../../domain/calculation/earnings_snapshot.dart';
import '../../domain/repositories/repositories.dart';
import '../local/mappers.dart';

/// Loads the financial records of [accountIds] into an [EarningsSnapshot]
/// and reloads it whenever one of the tables changes. Totals are always
/// derived from these authoritative records — there is no cached snapshot to
/// drift out of date. A combined account passes all of its members' ids; the
/// records are read, never copied.
class LocalEarningsDataSource implements EarningsDataSource {
  LocalEarningsDataSource(this.db, this.accountIds);
  final AppDatabase db;
  final Set<String> accountIds;

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
    if (accountIds.isEmpty) return EarningsSnapshot.empty;
    final ids = accountIds;
    // One transaction, so every table is read from the same database state.
    return db.transaction(() async {
      final sources = await (db.select(db.incomeSources)..where((t) => t.accountId.isIn(ids))).get();
      final revisions = await (db.select(db.rateRevisions)..where((t) => t.accountId.isIn(ids))).get();
      final pauses = await (db.select(db.sourcePauses)..where((t) => t.accountId.isIn(ids))).get();
      final overrides = await (db.select(db.dayOverrides)..where((t) => t.accountId.isIn(ids))).get();
      final items = await (db.select(db.compensationItems)..where((t) => t.accountId.isIn(ids))).get();
      final records = await (db.select(db.monthlyRecords)..where((t) => t.accountId.isIn(ids))).get();
      final ledger = await (db.select(db.ledgerEntries)..where((t) => t.accountId.isIn(ids))).get();
      return EarningsSnapshot(
        sources: sources.map((r) => r.toDomain()).toList(),
        revisions: revisions.map((r) => r.toDomain()).toList(),
        pauses: pauses.map((r) => r.toDomain()).toList(),
        overrides: overrides.map((r) => r.toDomain()).toList(),
        items: items.map((r) => r.toDomain()).toList(),
        monthlyRecords: records.map((r) => r.toDomain()).toList(),
        ledger: ledger.map((r) => r.toDomain()).toList(),
      );
    });
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
