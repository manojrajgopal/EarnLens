import 'package:drift/drift.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Profiles,
  Settings,
  IncomeSources,
  RateRevisions,
  SourcePauses,
  DayOverrides,
  CompensationItems,
  MonthlyRecords,
  LedgerEntries,
  CalendarEvents,
  AuditLog,
  NotificationHistory,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Bump when the schema changes and add a step in [migration].
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // Versioned, step-wise migrations go here, e.g.
          // if (from < 2) await m.addColumn(incomeSources, incomeSources.icon);
          // Every step must preserve existing rows; see docs/DATABASE_SCHEMA.md.
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Tables in an order that satisfies foreign keys when inserting.
  List<TableInfo<Table, dynamic>> get tablesInInsertOrder => [
        profiles,
        settings,
        incomeSources,
        rateRevisions,
        sourcePauses,
        dayOverrides,
        compensationItems,
        monthlyRecords,
        ledgerEntries,
        calendarEvents,
        auditLog,
        notificationHistory,
      ];
}
