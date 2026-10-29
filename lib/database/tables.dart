import 'package:drift/drift.dart';

// Conventions:
// * ids are UUID v4 text
// * calendar dates are ISO `yyyy-MM-dd` text, months `yyyy-MM`
// * timestamps are UTC microseconds since epoch (int)
// * money is integer minor units with an explicit currency code
// * financial tables use RESTRICT foreign keys: history is never cascaded away

@DataClassName('ProfileRow')
class Profiles extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get displayName => text().withLength(min: 1, max: 60)();
  TextColumn get currencyCode => text().withLength(min: 3, max: 3)();
  TextColumn get locale => text()();
  TextColumn get timezone => text()();
  TextColumn get dateOfBirth => text().nullable()();
  BoolColumn get onboardingComplete => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Typed preferences serialised as JSON per key.
@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {key};
}

@DataClassName('IncomeSourceRow')
class IncomeSources extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get kind => text()();
  TextColumn get category => text()();
  TextColumn get customCategory => text().nullable()();
  TextColumn get status => text()();
  TextColumn get currencyCode => text().withLength(min: 3, max: 3)();
  TextColumn get startDate => text()();
  TextColumn get endDate => text().nullable()();
  TextColumn get accrualPolicy => text()();
  IntColumn get workWeekdayMask => integer()();
  IntColumn get workStartMinute => integer()();
  IntColumn get workEndMinute => integer()();
  TextColumn get payRule => text()();
  IntColumn get payDay => integer()();
  IntColumn get payOffsetMonths => integer()();
  TextColumn get weekendAdjust => text()();
  TextColumn get expectedPayDate => text().nullable()();
  IntColumn get fixedTotalMinor => integer().nullable()();
  TextColumn get fixedTotalAccrual => text()();
  TextColumn get forecastMethod => text()();
  TextColumn get employer => text().nullable()();
  IntColumn get takeHomeMinor => integer().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get colorIndex => integer().withDefault(const Constant(0))();
  BoolColumn get isSample => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RateRevisionRow')
@TableIndex(name: 'idx_rate_revisions_source', columns: {#sourceId, #effectiveFrom})
class RateRevisions extends Table {
  TextColumn get id => text()();
  TextColumn get sourceId => text().references(IncomeSources, #id, onDelete: KeyAction.restrict)();
  TextColumn get effectiveFrom => text()();
  IntColumn get amountMinor => integer()();
  TextColumn get period => text()();
  TextColumn get changeType => text()();
  IntColumn get percentBps => integer().nullable()();
  TextColumn get note => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SourcePauseRow')
class SourcePauses extends Table {
  TextColumn get id => text()();
  TextColumn get sourceId => text().references(IncomeSources, #id, onDelete: KeyAction.restrict)();
  TextColumn get start => text()();
  TextColumn get endExclusive => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DayOverrideRow')
@TableIndex(name: 'idx_day_overrides_date', columns: {#date})
class DayOverrides extends Table {
  TextColumn get id => text()();
  TextColumn get sourceId => text().nullable().references(IncomeSources, #id, onDelete: KeyAction.restrict)();
  TextColumn get date => text()();
  TextColumn get type => text()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CompensationItemRow')
@TableIndex(name: 'idx_items_source', columns: {#sourceId})
class CompensationItems extends Table {
  TextColumn get id => text()();
  TextColumn get sourceId => text().nullable().references(IncomeSources, #id, onDelete: KeyAction.restrict)();
  TextColumn get type => text()();
  TextColumn get title => text().withLength(min: 1, max: 80)();
  TextColumn get currencyCode => text().withLength(min: 3, max: 3)();
  IntColumn get expectedMinor => integer().nullable()();
  TextColumn get expectedDate => text().nullable()();
  IntColumn get actualMinor => integer().nullable()();
  TextColumn get earnedDate => text().nullable()();
  TextColumn get recurrence => text()();
  BoolColumn get nonCash => boolean().withDefault(const Constant(false))();
  BoolColumn get countsAsEarnings => boolean().withDefault(const Constant(true))();
  BoolColumn get includeInForecast => boolean().withDefault(const Constant(true))();
  TextColumn get taxNote => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get cancelled => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MonthlyRecordRow')
class MonthlyRecords extends Table {
  TextColumn get id => text()();
  TextColumn get sourceId => text().references(IncomeSources, #id, onDelete: KeyAction.restrict)();
  TextColumn get month => text()();
  IntColumn get originalEstimateMinor => integer().nullable()();
  IntColumn get revisedEstimateMinor => integer().nullable()();
  IntColumn get actualMinor => integer().nullable()();
  BoolColumn get finalized => boolean().withDefault(const Constant(false))();
  IntColumn get finalizedAt => integer().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {sourceId, month},
      ];
}

@DataClassName('LedgerEntryRow')
@TableIndex(name: 'idx_ledger_source_period', columns: {#sourceId, #periodMonth})
@TableIndex(name: 'idx_ledger_date', columns: {#date})
class LedgerEntries extends Table {
  TextColumn get id => text()();
  TextColumn get sourceId => text().references(IncomeSources, #id, onDelete: KeyAction.restrict)();
  TextColumn get itemId => text().nullable().references(CompensationItems, #id, onDelete: KeyAction.restrict)();
  TextColumn get type => text()();
  IntColumn get amountMinor => integer()();
  TextColumn get currencyCode => text().withLength(min: 3, max: 3)();
  TextColumn get periodMonth => text()();
  TextColumn get date => text()();
  TextColumn get status => text()();
  TextColumn get dedupeKey => text().nullable().unique()();
  TextColumn get notes => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CalendarEventRow')
@TableIndex(name: 'idx_events_date', columns: {#date})
class CalendarEvents extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 80)();
  TextColumn get date => text()();
  TextColumn get type => text()();
  TextColumn get sourceId => text().nullable().references(IncomeSources, #id, onDelete: KeyAction.restrict)();
  IntColumn get amountMinor => integer().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get remind => boolean().withDefault(const Constant(false))();
  BoolColumn get cancelled => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AuditRow')
@TableIndex(name: 'idx_audit_entity', columns: {#entityType, #entityId})
class AuditLog extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get action => text()();
  TextColumn get summary => text()();
  TextColumn get beforeJson => text().nullable()();
  TextColumn get afterJson => text().nullable()();
  IntColumn get at => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('NotificationHistoryRow')
class NotificationHistory extends Table {
  TextColumn get key => text()();
  TextColumn get category => text()();
  TextColumn get title => text()();
  IntColumn get scheduledFor => integer()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {key};
}
