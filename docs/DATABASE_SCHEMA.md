# Database schema (version 1)

SQLite via Drift. Definitions: `lib/database/tables.dart`. Snapshot: `drift_schemas/drift_schema_v1.json`.

Conventions: UUID v4 text ids · dates as `yyyy-MM-dd` text, months as `yyyy-MM` · timestamps as UTC
microseconds (int) · money as integer minor units + 3-letter currency code · enums stored by stable
name · `PRAGMA foreign_keys = ON` with `RESTRICT` on financial references (no cascading deletes of
history).

| Table | Purpose | Key columns / constraints |
|---|---|---|
| `profiles` | Single-row profile | name, currency, locale, financial timezone, optional DOB, onboarding flag |
| `settings` | Typed preferences as JSON per key (`dashboard`, `appearance`, `security`, `notifications`, `calculation`, `backup`) | PK `key` |
| `income_sources` | Salary, recurring, temporary, variable, one-time sources | kind, category, status, currency, start/end dates, accrual policy, schedule (weekday mask, start/end minute), payment rule, fixed total, forecast method, `is_sample` |
| `rate_revisions` | Rate/estimate history | FK source; index `(source_id, effective_from)`; change type, optional % (bps) |
| `source_pauses` | Pause intervals | FK source; `end_exclusive` null while paused |
| `day_overrides` | Paid holidays / unpaid leave | optional FK source (null = all); index on date |
| `compensation_items` | Bonuses, benefits, allowances, one-time income | expected/actual amounts and dates, recurrence, non-cash, counts-as-earnings, include-in-forecast, cancelled |
| `monthly_records` | Variable income per month | UNIQUE `(source_id, month)`; original/revised estimate, actual, finalised |
| `ledger_entries` | Received, earned, adjustment, deduction, reversal | FK source + optional item; `period_month`; status; UNIQUE `dedupe_key`; indexes `(source_id, period_month)`, `date` |
| `calendar_events` | User events & reminders | index on date; cancelled flag |
| `audit_log` | Every change to financial data | entity type/id, action, summary, before/after JSON; index `(entity_type, entity_id)` |
| `notification_history` | Notifications *scheduled* (not delivered) | PK stable event key |

## Source-of-truth strategy

- Authoritative: rate revisions, pauses, overrides, items, monthly records, ledger entries.
- Derived on demand (never stored): accruals, monthly summaries, outstanding, forecasts, rates.
- Edits never delete history: corrections are new revisions/adjustments or audited updates;
  archiving keeps every row; a source can only be deleted while it has no financial records
  (sample data excepted).

## Duplicate prevention

`ledger_entries.dedupe_key` = `source|item|type|period|date|amount`. The repository rejects an
identical entry unless the user confirms (then the key is null). Cancelling/reversing an entry
releases its key. Restores and CSV imports use `INSERT OR IGNORE`, so re-importing never duplicates.

## Migrations

1. Change tables, bump `AppDatabase.schemaVersion`, add an `if (from < N)` step in `onUpgrade`.
2. `dart run drift_dev schema dump lib/database/app_database.dart drift_schemas/drift_schema_vN.json`
3. `dart run drift_dev schema generate drift_schemas/ test/generated_migrations/`
4. Extend `test/integration/migration_test.dart` with a data-preserving `N-1 → N` case.
5. If row shapes change, update `BackupService._migrateRow` so old backups still restore.

Every migration runs inside Drift's migration transaction; a failure leaves the previous schema intact.

## Web

The same schema runs on SQLite compiled to WebAssembly (`web/sqlite3.wasm`, `web/drift_worker.js`),
stored in OPFS or IndexedDB depending on browser support.
