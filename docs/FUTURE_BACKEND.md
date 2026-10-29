# Future backend & synchronisation

The app must always work without a server. A backend, if added, is opt-in and additive.

## What is already in place

- Repository interfaces (`lib/domain/repositories/repositories.dart`) for profile, settings,
  income sources/revisions/overrides, records (items, monthly records, ledger, events, audit) and
  the earnings read model. A remote or syncing implementation can wrap the local one.
- Globally unique UUID ids generated on device — no server-assigned ids needed.
- `createdAt`/`updatedAt` timestamps on records and a complete audit log of before/after states.
- A pure-Dart calculation engine with no Flutter dependencies — it can run unchanged in a Dart
  server (or be ported) so server-side reports match the app exactly.
- `NotificationProvider` interface for server-driven email/SMS/push.
- Versioned backup format usable as a full-snapshot upload.

## Proposed design

1. **Auth**: optional account (OAuth/OIDC), tokens in the secure store. No credentials in the app bundle.
2. **API**: REST, `/v1/...`, resources mirroring the tables; every write carries an
   **idempotency key** (the record id + revision counter) so retries never duplicate payments.
3. **Sync**: local DB remains the source of truth for the UI. Add per-row `revision` (monotonic)
   and `deleted_at` **tombstones** (a schema migration), plus an outbox table of pending changes.
   Pull with a server cursor; push the outbox.
4. **Conflicts**: never "last timestamp wins" for financial data.
   - Append-only data (ledger entries, revisions, audit) merges as a union, de-duplicated by id and
     dedupe key.
   - Mutable records (monthly actuals, items, source settings) use field-level three-way merge
     against the common ancestor revision; a true conflict (both sides changed the same amount)
     is surfaced to the user to resolve, with both values shown.
   - Finalised months are only changed through explicit reopen events.
5. **Cloud backup**: upload encrypted backups (client-side AES-GCM as today) — the server never sees
   plaintext unless the user opts into server features that need it.
6. **Server notifications**: the server stores notification preferences and sends email/SMS/push;
   the app registers a remote `NotificationProvider`.
7. **Privacy**: update docs/SECURITY.md and the in-app privacy screen before any data leaves the
   device; all of it opt-in.

No server dependency, SDK or remote configuration exists in the current build.
