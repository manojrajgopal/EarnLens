# Database schema (version 2)

SQLite via Drift. Definitions: `lib/database/tables.dart`. Ownership rules and limits: `lib/database/account_rules.drift`.
Snapshots: `drift_schemas/drift_schema_v1.json` and `drift_schemas/drift_schema_v2.json`.

Conventions: UUID v4 text ids · dates as `yyyy-MM-dd` text, months as `yyyy-MM` · timestamps as UTC
microseconds (int) · money as integer minor units + 3-letter currency code · enums stored by stable
name · `PRAGMA foreign_keys = ON` with `RESTRICT` on financial references (no cascading deletes of
history).

| Table | Purpose | Key columns / constraints |
|---|---|---|
| `profiles` | Single-row profile | name, currency, locale, financial timezone, optional DOB, onboarding flag |
| `settings` | Typed preferences as JSON per key. App-wide keys are `appearance`, `security`, `backup` and `activeView`. Per-account keys are `dashboard@<view>`, `notifications@<accountId>` and `calculation@<accountId>`. | PK `key` |
| `accounts` | Individual accounts (at most 10) | name (1–40), type, emoji, colour, optional photo (base64 PNG), description, currency, locale override, monthly target, `requires_pin`, archived, sort order |
| `combined_accounts` | Saved selections of two or more accounts. They hold no records. | name, avatar, display currency, UNIQUE `member_key` (sorted member ids) |
| `combined_account_members` | Membership rows | FK combined (`CASCADE`), FK account (`RESTRICT`); UNIQUE `(combined_account_id, account_id)`; index on `account_id` |
| `income_sources` | Salary, recurring, temporary, variable, one-time sources | FK `account_id` (`RESTRICT`, fixed once set); kind, category, status, currency, start/end dates, accrual policy, schedule (weekday mask, start/end minute), payment rule, fixed total, forecast method, `is_sample` |
| `rate_revisions` | Rate/estimate history | FK source; index `(source_id, effective_from)`; change type, optional % (bps) |
| `source_pauses` | Pause intervals | FK source; `end_exclusive` null while paused |
| `day_overrides` | Paid holidays / unpaid leave | optional FK source (null = all); index on date |
| `compensation_items` | Bonuses, benefits, allowances, one-time income | expected/actual amounts and dates, recurrence, non-cash, counts-as-earnings, include-in-forecast, cancelled |
| `monthly_records` | Variable income per month | UNIQUE `(source_id, month)`; original/revised estimate, actual, finalised |
| `ledger_entries` | Received, earned, adjustment, deduction, reversal | FK source + optional item; `period_month`; status; UNIQUE `dedupe_key`; indexes `(source_id, period_month)`, `date` |
| `calendar_events` | User events & reminders | index on date; cancelled flag |
| `audit_log` | Every change to financial data | nullable `account_id`; entity type/id, action, summary, before/after JSON; index `(entity_type, entity_id)` |
| `notification_history` | Notifications *scheduled* (not delivered) | PK stable event key (prefixed with the account id) |

Every financial table (`income_sources`, `rate_revisions`, `source_pauses`, `day_overrides`,
`compensation_items`, `monthly_records`, `ledger_entries`, `calendar_events`) has a NOT NULL
`account_id` with a foreign key to `accounts` and an index. Triggers keep each record's account equal
to its income source's account and cap `accounts` at 10 rows. See MULTI_ACCOUNTS.md.

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
3. `dart run drift_dev schema generate --data-classes --companions drift_schemas/ test/generated_migrations/`
4. Extend `test/integration/migration_test.dart` with a data-preserving `N-1 → N` case.
5. If row shapes change, update `BackupService._migrateRow` so old backups still restore.

Every migration runs inside Drift's migration transaction; a failure leaves the previous schema intact.

### v1 → v2 (multi-account)

`_migrateToV2` runs with `PRAGMA foreign_keys = OFF` and then checks `PRAGMA foreign_key_check`
before finishing. It:

1. Creates `accounts`, `combined_accounts` and `combined_account_members`.
2. If a profile or any income source exists, creates one **Personal** account in the profile
   currency.
3. Rebuilds the eight financial tables with `account_id` and fills it with that account
   (`TableMigration` with a constant column transformer). This keeps every row and all indexes.
4. Adds `audit_log.account_id`, creates the account indexes and the ownership triggers.
5. Renames `dashboard`, `notifications` and `calculation` settings to `<key>@<accountId>` and opens
   the account (`activeView`).

`test/integration/migration_test.dart` upgrades a v1 database with data and checks that rows,
amounts, settings and triggers survive.

## Web

The same schema runs on SQLite compiled to WebAssembly (`web/sqlite3.wasm`, `web/drift_worker.js`),
stored in OPFS or IndexedDB depending on browser support.
