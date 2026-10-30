# Architecture

EarnLens is a local-first Flutter app. Business rules are pure Dart, persistence is behind
repository interfaces, and UI features depend on both only through Riverpod providers.

```
                ┌──────────────────────── features/* (presentation) ───────────────────────┐
                │ accounts · dashboard · income_sources · salary · bonuses · transactions   │
                │ calendar · analytics · history · forecasts · settings · backup_restore    │
                └───────────────▲──────────────────────────────▲───────────────────────────┘
                                │ Riverpod providers            │
                ┌───────────────┴────────────┐   ┌──────────────┴──────────────┐
                │ bootstrap/dependency_      │   │ features/*/application       │
                │ injection.dart (DI graph)  │   │ (session, planners, sync)    │
                └───────▲─────────────▲──────┘   └──────────────▲──────────────┘
                        │             │                          │
        ┌───────────────┴──┐   ┌──────┴──────────────┐   ┌───────┴──────────────┐
        │ domain/          │   │ data/               │   │ core/                 │
        │  models          │◄──│  repositories (Drift)│   │  theme · routing      │
        │  calculation     │   │  backup · csv        │   │  security · formatting│
        │  repositories (if)│   │  local mappers       │   │  date_time · platform │
        │  services         │   └──────▲──────────────┘   └───────────────────────┘
        └──────────────────┘          │
                               ┌──────┴──────┐
                               │ database/   │  Drift (SQLite native / WASM web)
                               └─────────────┘
```

## Layers

| Layer | Path | Rules |
|---|---|---|
| Domain | `lib/domain/` | Pure Dart. No Flutter, Drift or plugins. Models, the calculation engine, repository interfaces, validators, dashboard preference rules. |
| Data | `lib/data/` | Drift-backed repository implementations, row ↔ model mappers, audit writer, backup and CSV services. |
| Database | `lib/database/` | Table definitions, migrations, connection factory. |
| Core | `lib/core/` | Cross-cutting: theme/tokens, router and shell, PIN/biometrics/secure store, money formatting, `LocalDate`, clock, platform channels. |
| Features | `lib/features/<name>/` | `presentation/` screens and widgets; `application/` state & orchestration; `domain/`/`data/` only where a feature owns them (notifications, widgets). |
| Shared UI | `lib/shared/widgets/` | Reusable cards, amount text with privacy masking, form fields, states. |

Business calculations never live in widgets, database classes or notification callbacks — screens
call `EarningsCalculator`, `RateCalculator`, `ForecastCalculator`, `PaymentScheduler` via providers.

## Accounts

Everything that shows financial data derives from the **active view** (`activeViewProvider`):

```
selectedViewProvider ─┐
accountsStreamProvider ├─► activeViewProvider ─► accountScopeProvider ─► income/records repositories
combinedAccounts… ─────┘                               │                 scopedSnapshotProvider(scope)
                                                       └─► currency, locale, per-view settings keys
```

- `AccountScope` decides what a repository can read and which single account it can write. A
  combined scope is read-only.
- `scopedSnapshotProvider` is an auto-disposed family keyed by scope. Each account has its own
  snapshot instance, which is preloaded by `AccountController.open` before the switch.
- Flows that write to an account that is not on screen (onboarding, sample data) use the
  account-bound providers `accountIncomeRepositoryProvider(id)` and similar ones.
- `AccountGate` (in the shell) covers PIN-protected views. `ReadOnlyGuard` wraps write routes.

Details: MULTI_ACCOUNTS.md.

## Data flow

1. Repositories write rows inside Drift transactions and append an `audit_log` row in the same
   transaction.
2. `LocalEarningsDataSource(db, accountIds).watchSnapshot()` listens to table updates and emits an
   immutable `EarningsSnapshot` of those accounts (coalescing bursts).
3. Providers derive summaries, rates, payments and forecasts from the snapshot. Nothing is cached in
   the database, so totals can't drift from the records.
4. The live counter watches a 1 Hz ticker and recomputes `liveTotal(range, now)`; other cards
   recompute only when data or the date changes (a minute ticker rolls `todayProvider` at midnight).
5. `NotificationService` plans reminders for every active account. Each account is planned with its
   own records and settings. `HomeWidgetService` publishes the active view. Both are debounced.

## Dependency injection

`lib/bootstrap/dependency_injection.dart` declares every provider. Platform services
(`databaseProvider`, secure store, biometrics, file service, notification provider, widget bridge,
clock, id generator) are overridable — tests inject an in-memory database, `FixedClock`,
`InMemorySecureStore` and sequential ids. `bootstrap/app_initializer.dart` builds the root
`ProviderContainer` with the real implementations.

## Navigation

`core/routing/app_router.dart` (GoRouter): onboarding gate → PIN lock gate → a
`StatefulShellRoute` with five branches (Home, Income, Calendar, Insights, Settings). Phones get a
floating pill bar; widths ≥ 840 px get a navigation rail. Deep links from notifications use the
same paths.

## Extending

- **New income type**: add an `IncomeKind`, handle it in `AccrualEngine.dayValue` (if continuous),
  `EarningsCalculator.summarizeSource` and `ForecastCalculator`, add a form section, tests and a row
  in CALCULATION_RULES.md.
- **New dashboard card**: add a `DashboardCardType` (unknown types are appended automatically to
  saved layouts), a provider in `dashboard_providers.dart`, and a widget in `dashboard_cards.dart`.
- **New notification channel**: implement `NotificationProvider` (see NOTIFICATIONS.md).
- **Remote sync**: see FUTURE_BACKEND.md.

## Key decisions

| Decision | Reason |
|---|---|
| Exact rationals + integer minor units | Deterministic, auditable money maths. |
| Day-value / accrual-window model | One mechanism covers month lengths, leap years, DST, revisions, working days, temporary work. |
| Snapshot recomputation instead of stored totals | No stale caches; corrections and reopened months recalculate automatically. |
| Key-value JSON settings | Preferences evolve without schema migrations; parsers tolerate missing keys. |
| No code generation for Riverpod | Fewer build steps; providers are plain declarations. |
| Drift with schema snapshots | Typed queries, transactions, and verifiable migrations (`drift_schemas/`). |
| `account_id` on every record, combined accounts as queries | Isolation is enforced by SQL, repositories and triggers. Combined figures can never drift from, duplicate or change member records. |
