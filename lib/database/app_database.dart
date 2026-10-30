import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Profiles,
    Settings,
    Accounts,
    CombinedAccounts,
    CombinedAccountMembers,
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
  ],
  include: {'account_rules.drift'},
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Bump when the schema changes and add a step in [migration].
  ///
  /// * v1 — single-account EarnLens 1.x.
  /// * v2 — multi-account: `accounts`, `combined_accounts`,
  ///   `combined_account_members`, and `account_id` on every financial table.
  @override
  int get schemaVersion => 2;

  /// Settings keys that became per-account in v2.
  static const perAccountSettingKeys = ['dashboard', 'calculation', 'notifications'];

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // Foreign keys are enforced from beforeOpen, after migrations; keep
          // them off while tables are rebuilt and verify integrity at the end.
          await customStatement('PRAGMA foreign_keys = OFF');
          if (from < 2) await _migrateToV2(m);
          final problems = await customSelect('PRAGMA foreign_key_check').get();
          if (problems.isNotEmpty) {
            throw StateError('Migration $from→$to left ${problems.length} broken references; rolled back.');
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// v1 → v2. Every existing record is assigned to one new individual
  /// account ("Personal"), so nothing is lost and EarnLens 1.x users see
  /// exactly the same data in their first account.
  Future<void> _migrateToV2(Migrator m) async {
    await m.createTable(accounts);
    await m.createTable(combinedAccounts);
    await m.createTable(combinedAccountMembers);
    await m.createIndex(idxCombinedMembersAccount);

    final profile =
        await customSelect('SELECT currency_code FROM profiles LIMIT 1').getSingleOrNull();
    final hasSources = (await customSelect('SELECT 1 FROM income_sources LIMIT 1').get()).isNotEmpty;
    final accountId = const Uuid().v4();
    final createAccount = profile != null || hasSources;
    if (createAccount) {
      final now = DateTime.now().toUtc().microsecondsSinceEpoch;
      await into(accounts).insert(AccountsCompanion.insert(
        id: accountId,
        name: 'Personal',
        type: 'personal',
        avatarEmoji: const Value('🙂'),
        currencyCode: profile?.read<String>('currency_code') ?? 'INR',
        createdAt: now,
        updatedAt: now,
      ));
    }

    final owner = Constant(accountId);
    await m.alterTable(TableMigration(incomeSources,
        newColumns: [incomeSources.accountId], columnTransformer: {incomeSources.accountId: owner}));
    await m.alterTable(TableMigration(rateRevisions,
        newColumns: [rateRevisions.accountId], columnTransformer: {rateRevisions.accountId: owner}));
    await m.alterTable(TableMigration(sourcePauses,
        newColumns: [sourcePauses.accountId], columnTransformer: {sourcePauses.accountId: owner}));
    await m.alterTable(TableMigration(dayOverrides,
        newColumns: [dayOverrides.accountId], columnTransformer: {dayOverrides.accountId: owner}));
    await m.alterTable(TableMigration(compensationItems,
        newColumns: [compensationItems.accountId], columnTransformer: {compensationItems.accountId: owner}));
    await m.alterTable(TableMigration(monthlyRecords,
        newColumns: [monthlyRecords.accountId], columnTransformer: {monthlyRecords.accountId: owner}));
    await m.alterTable(TableMigration(ledgerEntries,
        newColumns: [ledgerEntries.accountId], columnTransformer: {ledgerEntries.accountId: owner}));
    await m.alterTable(TableMigration(calendarEvents,
        newColumns: [calendarEvents.accountId], columnTransformer: {calendarEvents.accountId: owner}));
    await m.addColumn(auditLog, auditLog.accountId);

    for (final index in [
      idxSourcesAccount,
      idxRevisionsAccount,
      idxPausesAccount,
      idxOverridesAccount,
      idxItemsAccount,
      idxMonthlyAccount,
      idxLedgerAccount,
      idxEventsAccount,
    ]) {
      await m.createIndex(index);
    }
    for (final trigger in allSchemaEntities.whereType<Trigger>()) {
      await m.createTrigger(trigger);
    }

    if (createAccount) {
      await customUpdate('UPDATE audit_log SET account_id = ?', variables: [Variable(accountId)], updates: {auditLog});
      for (final key in perAccountSettingKeys) {
        await customUpdate(
          'UPDATE settings SET key = ? WHERE key = ?',
          variables: [Variable('$key@$accountId'), Variable(key)],
          updates: {settings},
        );
      }
      await into(settings).insertOnConflictUpdate(SettingsCompanion.insert(
        key: 'activeView',
        value: jsonEncode({'kind': 'account', 'id': accountId}),
        updatedAt: DateTime.now().toUtc().microsecondsSinceEpoch,
      ));
    }
  }

  /// Tables in an order that satisfies foreign keys when inserting.
  List<TableInfo<Table, dynamic>> get tablesInInsertOrder => [
        profiles,
        settings,
        accounts,
        combinedAccounts,
        combinedAccountMembers,
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
