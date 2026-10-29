# Contributing to EarnLens

## Ground rules

1. **Accuracy first.** Any change to calculations or financial data handling needs tests and an
   update to `docs/CALCULATION_RULES.md` in the same change.
2. **No floating point for money.** Use integer minor units and `Fraction`; round only at
   boundaries with `roundHalfEven`.
3. **No business logic in widgets.** Screens call calculators/repositories through providers.
4. **Never delete history to make something work.** Use revisions, adjustments, audited updates,
   archiving.
5. **Use the injected clock** (`clockProvider`, `FinancialCalendar`) — never `DateTime.now()` in
   domain or feature code.
6. **Privacy:** never log amounts, PINs or personal data; render amounts through `AmountText`.
7. **No network dependencies** in the default build.

## Workflow

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # after changing Drift tables
flutter analyze                                            # must be clean
flutter test                                               # must pass
```

- Schema change → bump `schemaVersion`, write the migration step, dump the schema
  (`drift_schemas/`), regenerate helpers, extend `test/integration/migration_test.dart`
  (see docs/DATABASE_SCHEMA.md).
- New route → add it to `core/routing/app_router.dart` **and** to
  `test/widget/screens_smoke_test.dart` so it is rendered at phone and desktop widths.
- UI uses design tokens from `core/theme/tokens.dart` and components from `shared/widgets/`.
  Keep touch targets ≥ 48 dp, add `Semantics` labels, and respect `MediaQuery.disableAnimations`.

## Commit style

Small, focused commits with an imperative subject (“Add quarterly bonus recurrence”). Describe any
change to financial behaviour explicitly in the body.
