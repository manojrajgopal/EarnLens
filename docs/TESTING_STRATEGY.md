# Testing strategy

All tests run offline and deterministically: the calculation engine takes explicit instants, the
app uses an injectable `Clock`, ids are injectable, and the database is in-memory SQLite.

```bash
flutter test                         # everything
flutter test test/unit               # calculation engine, services, PIN, planner, formatting
flutter test test/integration        # Drift DB, repositories, backup/restore, CSV, migrations
flutter test test/widget             # onboarding, PIN lock, dashboard, forms
```

| Suite | Covers |
|---|---|
| `unit/calculation/accrual_engine_test.dart` | month lengths, leap years, half-open boundaries, year boundary, joining/leaving mid-month, revisions, pauses, unpaid leave, working-day policy & hours, holidays, hourly rates, temporary work (rate, spread, on completion), DST, timezone independence, randomised month sums |
| `unit/calculation/rates_summary_forecast_test.dart` | all earning units, payment due dates/weekend shift/statuses, payment vs accrual separation, adjustments, deductions, currency isolation, variable income (variance, estimate vs actual, no double counting), items, recurring projections, year forecast, what-if |
| `unit/calculation/money_and_dates_test.dart` | Fraction arithmetic & rounding, money parsing, LocalDate/YearMonth/DateRange |
| `unit/services_test.dart` | dashboard preference invariants, PIN hashing/rate limiting, notification planner (opt-in, keys, privacy, quiet hours), formatting |
| `integration/repositories_test.dart` | DB creation & FKs, CRUD + audit, validation rollback, duplicate guard, archive vs delete, pause/resume, month finalise/reopen, snapshot stream, sample data removal |
| `integration/backup_csv_test.dart` | backup round trip, encryption, tamper detection, version checks, merge idempotency, failed-restore rollback, CSV export/import/validation/escaping |
| `integration/migration_test.dart` | live schema matches `drift_schemas/` snapshot |
| `widget/app_flow_test.dart` | onboarding flow, PIN creation/lock/unlock, dashboard rendering, customisation |
| `widget/refresh_and_nav_test.dart` | pull-to-refresh threshold, short pulls, normal scrolling, no concurrent refreshes, error recovery, empty lists, horizontal carousels ignored, refresh writes no records; tab state preserved, back at a tab root returns Home, centre orb opens Insights |
| `widget/screens_smoke_test.dart` | every route rendered with sample data at 360 px and 1280 px; fails on any overflow or exception |
| `tools/screenshot*_test.dart` | opt-in visual harnesses (`--dart-define=SCREENSHOTS=true --update-goldens`) for several device sizes, notch/gesture/3-button insets, dark mode and refresh frames → `build/screens/` |

## Required regression tests (spec §24.4)

| # | Requirement | Test |
|---|---|---|
| 1 | Salary payment doesn't duplicate accrual | *REGRESSION: recording a salary payment does not duplicate earnings* |
| 2 | Hike doesn't change earlier months | *a hike only affects days from its effective date* |
| 3 | Editing estimate keeps actual | *REGRESSION: editing an estimate does not overwrite the actual* (unit + integration) |
| 4 | Temporary job stops after end | *day-rate job stops accruing after its end date* |
| 5 | Reopen & edit recalculates | *original estimate is preserved; finalised months need reopening* |
| 6 | Live counter after app closed | *live counter recomputed after a long gap equals continuous ticking* |
| 7 | Duplicate restore/import | *REGRESSION: restoring the same backup twice (merge) never duplicates*, *export then import detects duplicates* |
| 8 | Failed restore doesn't corrupt | *REGRESSION: a failed restore leaves existing data untouched*, *validation rejects invalid sources and rolls back* |
| 9 | One rate always selected | *REGRESSION: at least one earning rate always remains selected* |
| 10 | Timezone change doesn't rewrite history | *the same instant is interpreted by the financial timezone, not the device* |
| 11 | Rounding doesn't accumulate | *rounding displayed per-second values does not leak into totals* |
| 12 | Month/year transitions | *adjacent half-open ranges do not double count the boundary*, *year boundary splits correctly* |

## Not automated

- On-device runs (notification delivery, biometric prompt, home-screen widget rendering) — verify
  manually on a device/emulator; see the checklist in README.md.
- iOS build (requires macOS).
