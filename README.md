# EarnLens

**Personal earnings intelligence, live income tracker and financial dashboard.**

EarnLens shows how much you have earned — live, to the second — across salary, freelance work,
part-time and temporary jobs, business, rental and other income. It keeps expected, actual and
received money separate, preserves every historical change, and works completely offline. No
account, no server, no tracking.

## Highlights

- **Live earnings engine** — computed from your pay rules and the clock with exact rational maths,
  so the counter is correct after the app was closed, the phone restarted or the timezone changed.
  Calendar-day or working-day accrual, real month lengths, leap years, DST, mid-month joining/leaving,
  salary revisions, pauses, holidays and unpaid leave. Spec: [docs/CALCULATION_RULES.md](docs/CALCULATION_RULES.md).
- **Configurable rates** — per second … per year; choose which appear, their order, the main rate,
  precision, and whether hourly figures use 24-hour days or your working hours.
- **All income types** — salary (with payment rules separate from accrual, hikes and retro
  adjustments), fixed recurring, temporary/part-time (rate or fixed total), variable business/freelance
  income (original vs revised estimate vs actual, month finalise/reopen), one-time income, bonuses,
  benefits, allowances and reimbursements.
- **Transactions** — payments received, deductions, reversals, adjustments; duplicate protection;
  expected-payment statuses (upcoming, due, overdue, partial, received).
- **Multiple accounts**
  - Up to 10 accounts (Personal, Family, Business, Freelance…), each with its own income,
    payments, history, dashboard, reminders, currency and optional PIN.
  - Switching is instant from the dashboard.
  - **Combined accounts** add up any two or more accounts live. They are read-only, never copy
    records, never mix currencies and never duplicate a combination.
  - Accounts are local data sets, not logins. See [docs/MULTI_ACCOUNTS.md](docs/MULTI_ACCOUNTS.md).
- **Customisable dashboard** — 16 card types, reorder, resize, per-card source filters.
- **Calendar, insights, forecasts & what-if** — trends, distribution, expected vs actual, MoM/YoY,
  month-end and year-end estimates, hypothetical hikes/extra income.
- **Security** — PIN (salted PBKDF2, rate-limited), optional biometrics, auto-lock, privacy mode.
- **Reminders** — local notifications for paydays, overdue payments, bonuses, month-end reviews.
- **Android home-screen widget**.
- **Backups** — versioned, integrity-checked, optionally AES-256-GCM encrypted; transactional
  restore (replace or merge); CSV export and validated import.
- **Audit trail** of every change.

## Getting started

Requirements: Flutter 3.47 (stable, Dart 3.13), Android SDK 36+, JDK 17–21.

```bash
flutter pub get
flutter run                  # device/emulator
flutter run -d chrome        # web
```

If your default Java is newer than Gradle supports (e.g. JDK 26):

```bash
flutter config --jdk-dir="C:\Program Files\Java\jdk-21"
```

### Builds

```bash
flutter build apk --release      # Android → build/app/outputs/flutter-apk/EarnLens.apk
flutter build web --release      # Web (see docs/PLATFORM_SUPPORT.md for hosting headers)
```

iOS can only be compiled on macOS (`flutter build ios` does not exist on Windows). The CI workflow
builds `EarnLens.ipa` on a GitHub-hosted Mac on every push to `main` (or on demand from
**Actions → CI → Run workflow**); download it from the run's artifacts and install it from Windows
as described in [docs/IOS_INSTALL.md](docs/IOS_INSTALL.md).

### Tests

```bash
flutter analyze
flutter test                     # 120 unit, integration and widget tests (+ opt-in screenshot harnesses)
```

See [docs/TESTING_STRATEGY.md](docs/TESTING_STRATEGY.md) for the suites and the mapping of each
required regression test.

### Regenerating code

Drift tables are code-generated:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Project layout

```
lib/
  bootstrap/        DI graph (Riverpod) and app start-up
  core/             theme & tokens, routing & shell, security, formatting, dates, platform
  database/         Drift tables & migrations
  domain/           models, calculation engine, repository interfaces, validators (pure Dart)
  data/             local repositories, mappers, audit writer, backup & CSV
  features/         onboarding, authentication, dashboard, income_sources, salary, bonuses,
                    transactions, variable_income, calendar, analytics, history, forecasts,
                    notifications, widgets, backup_restore, settings, help
  shared/widgets/   reusable UI components
test/               unit · integration · widget · helpers
docs/               architecture, calculations, schema, security, backup, notifications,
                    testing, platforms, future backend
drift_schemas/      versioned schema snapshots for migration tests
```

## Documentation

| Topic | Document |
|---|---|
| Architecture & extension points | [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) |
| Design system, safe areas, navigation, pull-to-refresh, app icon | [docs/DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md) |
| Every formula, with examples | [docs/CALCULATION_RULES.md](docs/CALCULATION_RULES.md) |
| Accounts, combined accounts, isolation & account PINs | [docs/MULTI_ACCOUNTS.md](docs/MULTI_ACCOUNTS.md) |
| Database schema & migrations | [docs/DATABASE_SCHEMA.md](docs/DATABASE_SCHEMA.md) |
| Security & privacy | [docs/SECURITY.md](docs/SECURITY.md) |
| Backup, restore, CSV | [docs/BACKUP_AND_RESTORE.md](docs/BACKUP_AND_RESTORE.md) |
| Notifications | [docs/NOTIFICATIONS.md](docs/NOTIFICATIONS.md) |
| Testing | [docs/TESTING_STRATEGY.md](docs/TESTING_STRATEGY.md) |
| Platforms, builds, limitations | [docs/PLATFORM_SUPPORT.md](docs/PLATFORM_SUPPORT.md) |
| Future backend & sync | [docs/FUTURE_BACKEND.md](docs/FUTURE_BACKEND.md) |

## Status

| Area | Status |
|---|---|
| Calculation engine, persistence, backup, security, all screens | Implemented and covered by automated tests |
| Android | Builds; manual on-device QA pending (notifications, biometrics, widget) |
| Web | Builds; persistence via SQLite WASM |
| iOS | Code and configuration in place; build not verified (needs macOS) |
| iOS WidgetKit widget, PDF reports, SQLCipher database encryption | Deferred — see docs |

### Manual QA checklist (device)

1. Onboard, create a PIN, background the app past the auto-lock delay → lock screen appears.
2. Enable reminders → a payday reminder appears in the system's scheduled notifications.
3. Enable privacy mode → app switcher preview is blank (Android).
4. Add the home-screen widget → shows "Estimate as of HH:mm".
5. Create an encrypted backup, delete all data, restore → data returns.

## Licences

App code: proprietary to the project owner. Bundled font: Urbanist (SIL Open Font License 1.1,
`assets/fonts/OFL.txt`). Third-party package licences are listed in-app under Settings › About ›
Open-source licences.
