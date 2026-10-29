# Backup, restore, import & export

All of this works offline, without an account. Implementation: `lib/data/backup/`, UI in
`lib/features/backup_restore/`.

## Backup file (`.earnlens`, JSON)

```json
{
  "format": "earnlens-backup", "formatVersion": 1, "schemaVersion": 1,
  "appVersion": "0.1.0+1", "createdAt": "2024-11-15T06:00:00.000Z",
  "counts": { "income_sources": 3, "ledger_entries": 42, "...": 0 },
  "sha256": "<hex digest of the payload JSON>",
  "payload": { "tables": { "<table>": [ { row }, ... ] } },
  "cipher": { "alg": "AES-256-GCM", "kdf": "PBKDF2-HMAC-SHA256", "iterations": 210000,
              "salt": "b64", "nonce": "b64", "ciphertext": "b64", "mac": "b64" }
}
```

Exactly one of `payload` (unencrypted) or `cipher` (encrypted) is present. Included: profile,
settings, all financial tables, calendar events, audit log. Excluded: the PIN (secure store) and
notification scheduling history (device-specific).

Creating a backup: Settings › Data › Create backup → optional password → save via the system file
dialog (Android SAF / iOS Files / browser download) or share sheet. "Last backup" is recorded and a
reminder can be scheduled.

## Restore

1. Pick a file → if encrypted, enter the password.
2. **Validation before anything changes**: format marker, format/schema version (newer → rejected
   with "update the app"), decryption/authentication, SHA-256 integrity, every row parses into its
   table type, and referential integrity (every ledger entry, revision, item… points to an existing
   source/item).
3. A preview shows the creation date, app version and record counts.
4. Choose:
   - **Replace** — deletes all local data and loads the backup.
   - **Merge** — keeps current data and adds backup records whose ids are new. Existing ids and
     duplicate ledger keys are skipped (reported as "skipped"), so restoring the same backup twice
     never duplicates anything. The device's profile and settings are kept.
5. The restore runs in **one database transaction**: any failure rolls back and the existing data
   is untouched (regression test: *a failed restore leaves existing data untouched*).

Older backups pass through `BackupService._migrateRow` (hook for future schema versions).

## CSV export

- **Transactions**: `date, period_month, source, type, amount, currency, status, notes` — filter by
  source and date range.
- **Monthly summary**: per month and source: expected, actual, received, deductions, outstanding,
  variance.
- RFC 4180 quoting; cells starting with `= + - @` (non-numeric) are prefixed with `'` to prevent
  spreadsheet formula injection; UTF-8 with BOM.

## CSV import (transactions)

Columns: `date` (yyyy-mm-dd), `source` (existing source name), `type` (`received`, `earned`,
`adjustment`, `deduction`, `reversal`), `amount`; optional `period_month`, `currency`, `status`,
`notes`. Every line is validated first; **if any line is invalid nothing is imported** and each
problem is listed with its line number. Exact duplicates of existing entries are skipped and counted.

## Web caveat

Browser storage can be cleared by the user or the browser and is not shared between browsers or
devices. Back up regularly when using the web version.
