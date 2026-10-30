# Accounts and combined accounts (EarnLens 2.0)

EarnLens keeps up to **10 individual accounts** on one device, for example Personal, Family and a
freelance business. Each account has its own income sources, rates, payments, bonuses, monthly
figures, holidays, calendar events, dashboard layout, reminder settings and calculation defaults.
An account is a separate set of data on this device. It is **not** a separate login or cloud
identity.

**Combined accounts** add up two or more individual accounts. They store no financial records of
their own and do not count toward the limit of 10.

## Concepts

| Term | Meaning |
|---|---|
| `Account` | An individual account (`accounts` table). It owns records through `account_id`. |
| `CombinedAccount` | A saved set of member accounts (`combined_accounts` + `combined_account_members`). |
| `AccountView` | What is on screen: `IndividualView(id)` or `CombinedView(id)`. It is persisted under the `activeView` setting. |
| `AccountScope` | The accounts a repository or snapshot may read (`visibleAccountIds`), and the one account it may write (`writableAccountId`). A combined view has no writable account. |

## Isolation

Data from one account must never appear in another account. Isolation is enforced at three levels:

1. **Queries.** Every repository read filters on `account_id IN (visible accounts)`. Snapshots are
   loaded per scope (`LocalEarningsDataSource(db, accountIds)`).
2. **Repositories.** Writes are stamped with the scope's writable account, whatever the model says.
   Before an update or delete, the repository checks that the existing row, and its source or item,
   belong to that account. Otherwise it throws `AccountOwnershipException`. In a combined scope,
   every write throws `ReadOnlyViewException`.
3. **Database triggers** (`lib/database/account_rules.drift`):
   - A child record must have the same `account_id` as its income source (`EARNLENS_ACCOUNT_MISMATCH`).
   - A ledger entry's item must belong to the same account.
   - A source can never move to another account.
   - A database can hold at most 10 accounts (`EARNLENS_ACCOUNT_LIMIT`).

A holiday recorded for "all sources" applies only to the sources of its own account, so combined
views never mix calendars.

## Switching

`AccountController.open(view)` preloads the new view's snapshot first. It then switches the
selected view and persists it. Each scope has its own snapshot provider instance
(`scopedSnapshotProvider(scope)`), so a newly opened account starts from its own data and never
from the previous account's figures. Switching only changes which records are read: it never
writes, copies or deletes financial records.

At launch, `app_initializer` restores the last view before the first frame. If the restored account
no longer exists, the first active account is opened instead (`resolveView`).

## Combined accounts

- **Members.** A combined account needs at least two distinct individual accounts. An account
  cannot appear twice. A combined account cannot include itself or another combined account. A
  circular relationship is therefore impossible.
- **Duplicates.** Each combined account stores `member_key`: its member ids, sorted and joined
  (`UNIQUE`). Selecting the same accounts in any order gives the same key. The create screen warns
  as soon as the selection matches an existing combination and offers to open that one. The
  repository throws `DuplicateCombinationException` if a duplicate is saved anyway.
- **Figures.** The combined snapshot is the union of the members' records, so the calculation
  engine is the same as everywhere else. The member breakdown uses `EarningsSnapshot.subset({id})`.
  Results are recalculated from records every time; nothing is stored.
- **Currencies.** Totals are shown in the combined account's chosen currency. Members' income in
  other currencies is listed separately ("Not included in INR totals: …"). Nothing is converted.
- **Read-only.**
  - Edit buttons are hidden.
  - Write routes show a `ReadOnlyGuard`. It names the account that owns the record and offers
    "Open <name>".
  - Repositories refuse writes.
  - Tapping a member opens a read-only breakdown. Switching to the member's account is a separate,
    explicit step.
- **Management.**
  - You can rename a combined account and change its avatar and currency.
  - Adding or removing members recalculates the figures immediately.
  - Deleting a combined account removes only its configuration and dashboard layout. Member data
    is kept.

## Deleting an individual account

The confirmation screen shows the impact before anything is deleted (`AccountRepository.previewDelete`).
To confirm, you type the account's name, and a protected account also asks for its PIN. Then, in
one transaction:

- Its records, audit rows and per-account settings are deleted.
- It is removed from every combined account. A combined account left with fewer than two members,
  or one that now matches another combination, is removed (only its configuration).
- Other accounts are not touched.
- The last remaining account cannot be deleted.

Archiving instead hides an account from the switcher and keeps everything.

## Per-account settings

| Setting key | Scope |
|---|---|
| `dashboard@<accountId>` / `dashboard@combined:<id>` | Cards, visible rates and live counter of a view |
| `notifications@<accountId>` | Reminder preferences of an account |
| `calculation@<accountId>` | Defaults for new income sources of an account |
| `appearance`, `security`, `backup`, `activeView` | App-wide |

The account itself stores its currency, number format (locale override), monthly target, avatar
(emoji, colour, or a 192 px PNG photo) and description.

## Account PIN

An account can have its own PIN in addition to the app PIN. An app PIN is required first.
- The verifier is stored in the secure store under `account.<id>.pin.*`. It uses the same
  PBKDF2 verifier, failure counter and lockout as the app PIN, and the PIN itself is never stored.
- While locked, the account's scope is empty, so its data is not loaded. The `AccountGate` covers
  the screen, and the switcher shows "Protected" instead of a figure.
- A combined account asks for the PIN of each protected member.
- Unlocks last until the app locks again.
- Reminders for a protected account show a generic text with no names or amounts. The home-screen
  widget hides amounts whenever a protected account is part of the view.
- Backups do not contain PINs. Restored accounts start unprotected, and the PIN can be set again.

## Limits and future work

- Ten individual accounts per device. Combined accounts are unlimited.
- Accounts are local. A future backend can map `account_id` to a server-side owner (see
  FUTURE_BACKEND.md). The repository interfaces already take an `AccountScope`.
