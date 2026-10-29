# Calculation rules

This is the specification of every number EarnLens shows. The implementation lives in
`lib/domain/calculation/` and is covered by `test/unit/calculation/`. Code and this
document must change together.

## 1. Money representation

- Amounts are stored as **integer minor units** (paise, cents) with an explicit ISO currency code.
- All intermediate maths uses **exact rationals** (`Fraction`, backed by `BigInt`). No floating
  point is used for authoritative values.
- Rounding happens once, at a boundary (display, CSV, persistence of a derived figure), using
  **round half to even** (banker's rounding).
- Totals are always recomputed from the rules — never by adding up previously rounded display values.
  Example: ₹35,000/month in a 31-day month is ₹0.01306899… per second. Displaying it as ₹0.0131
  and multiplying by 2,678,400 seconds would give ₹35,087; EarnLens computes the month exactly as
  ₹35,000.00 (test: *rounding displayed per-second values does not leak into totals*).
- Totals never mix currencies. Dashboards and summaries include only sources in the profile
  currency; other sources show their own figures on their detail page.

## 2. Time model

- **Financial timezone**: an IANA zone stored in the profile (default: device zone at onboarding).
  It decides where each calendar day starts and ends. It is *not* the device timezone, so travelling
  or changing the phone's clock zone does not change calculations.
- **Dates** (joining date, effective dates, pay dates, earned dates) are stored as calendar dates
  (`yyyy-MM-dd`) and are never reinterpreted.
- **Instants** are UTC microseconds. "Now" comes from an injectable `Clock`.
- **Intervals are half-open**: `[start, end)`. A day is `[00:00, next 00:00)` in the financial
  timezone; a month is `[1st, 1st of next month)`. An end date entered by the user (last working
  day, project end) is **inclusive**, converted internally to an exclusive bound of the next day.
- **DST**: a 23- or 25-hour day still has exactly one day value; accrual within that day is spread
  over its real length (test: *a 23-hour DST day still accrues exactly one day value*).
- Changing the financial timezone does not change stored dates or completed-month totals. It only
  changes where *today's* partial accrual begins.

## 3. Day values and accrual windows

Every rule-based source (salary, fixed recurring, temporary work) assigns each eligible local day
a **day value**. The value accrues **linearly** across that day's **accrual window**:

| Policy | Accrual window |
|---|---|
| Calendar-day | the whole day `[00:00, 24:00)` |
| Working-day (and every hourly rate) | the configured work window, e.g. `[09:00, 18:00)` on working days only |

```
earned(from, to) = Σ_days dayValue(d) × |[from,to) ∩ window(d)| / |window(d)|
```

The live counter evaluates this formula for "now" every second. It is never incremented, so it is
exact after the app is closed, the device restarts or the clock jumps (regression test: *live
counter recomputed after a long gap equals continuous ticking*). The counter can never exceed the
amount defined by the rules.

### 3.1 Eligibility

A day earns nothing when it is before the start date, after the inclusive end date, inside a pause
interval, or has no applicable rate.

### 3.2 Rates and revisions

A source has one or more **rate revisions** `(effectiveFrom, amount, period)`. The revision in
force on day *d* is the latest with `effectiveFrom ≤ d`; on the same date the most recently created
wins. Revisions are never overwritten by a pay change — a hike is a new revision, so months before
its effective date are unchanged (regression test: *a hike only affects days from its effective
date*). Retroactive arrears are recorded as a separate **adjustment** entry in the period they
correct (§6).

### 3.3 Day value by period and policy

`A` = revision amount, `D(m)` = days in the calendar month, `W(m)` = working days in the month
(scheduled weekdays minus paid holidays), `w` = working weekdays per week, `h` = scheduled hours.

| Period | Calendar-day policy | Working-day policy (working days only) |
|---|---|---|
| month | `A / D(m)` | `A / W(m)` |
| year | `A / 12 / D(m)` | `A / 12 / W(m)` |
| week | `A / 7` | `A / w` |
| day | `A` | `A` |
| hour | — (requires working-day policy) | `A × h` |

Worked example, ₹35,000/month, calendar-day policy:

| Month length | Day value |
|---:|---:|
| 28 days | ₹1,250.00 |
| 29 days | ₹1,206.8965… |
| 30 days | ₹1,166.6666… |
| 31 days | ₹1,129.0322… |

A full month always totals exactly `A`. Joining on 11 October (21 of 31 days) on ₹31,000 earns
exactly ₹21,000 in October.

### 3.4 Holidays, unpaid leave and pauses

- **Paid holiday** (working-day policy): not a working day; it is removed from `W(m)`, so the
  monthly salary is spread over the remaining days and the month total is unchanged.
- **Unpaid leave**: counted in `W(m)` (or `D(m)`) but earns zero, so pay is reduced by one day's
  value. Applies to both policies.
- **Pause**: like unpaid leave for every day in the pause interval.
- Partial working days are not modelled: a working day is either worked (full window) or leave.

### 3.5 Temporary work with a fixed total

| Rule | Day value |
|---|---|
| Spread over calendar days | `total / days in [start, end]` |
| Spread over working days | `total / working days in [start, end]` on working days, accruing in the work window |
| Earned on completion | `0`, then the whole total at the instant the last day's window closes |

The completion amount is attributed to the period containing the end date (`from < t ≤ to`).
Accrual always stops after the end date (regression test: *temporary job stops accruing after its
end date*). A fixed total is never divided by an arbitrary number of days: the user picks one of
these rules.

## 4. Earning rates (per second … per year)

Rates are **nominal**: the earnings at the rate in force on the reference date (today), assuming
the source is eligible. Ended or paused sources show zero.

| Unit | Definition |
|---|---|
| month | sum of nominal day values across the current calendar month |
| quarter | sum across the three months of the current quarter |
| year | sum across the twelve months of the current year |
| day | calendar policy: today's day value (`A / D(m)`); working policy: value of a working day this month |
| week | sum of nominal day values for the 7 days starting today |
| hour — *around the clock* basis | calendar sources: day / 24; working sources: week / 168 |
| hour — *working hours* basis | working sources: day / scheduled hours; calendar sources: week / scheduled weekly hours |
| minute, second | hour / 60, minute / 60 |

The default basis is *around the clock*, which matches the calendar-day live counter exactly
(test: *per-second matches the live counter within the day*). EarnLens never silently mixes a
calendar-day salary with an assumed 8-hour day: the basis is an explicit, labelled setting.

## 5. Variable income (business, freelance)

For each source and month the app keeps, separately:

- **original estimate** — the first estimate ever entered (never overwritten);
- **revised estimate** — the latest change, if any;
- **actual** — the real figure, when known;
- **finalised** flag — a finalised actual can only change after the month is reopened (audited).

Default monthly estimate: the source's latest *estimate* revision. Expected = revised ?? original ??
default.

**Source of truth for actual earnings** (prevents double counting):

1. If a monthly actual total is recorded, it *is* the actual. Detailed "income earned" entries for
   that month are informational and are not added on top.
2. Otherwise, the actual is the sum of "income earned" entries dated in the month (up to today).
3. Otherwise there is no actual yet (shown as "No actuals yet").

Variance = actual − expected (e.g. expected ₹20,000, actual ₹24,500 → +₹4,500). Money received is
tracked independently.

For custom ranges that cover part of a month, a recorded monthly total is prorated by days;
detailed entries are counted by their dates.

## 6. Ledger: earned vs received

| Entry type | Affects | Attribution |
|---|---|---|
| Payment received | received only | earning period (`periodMonth`) |
| Refund / reversal | received (−) | earning period |
| Deduction (tax, PF) | deductions | earning period |
| Earnings adjustment (signed) | actual earnings | earning period |
| Income earned (variable/one-time) | actual earnings (rule §5) | entry date |

- Recording a salary payment **never** creates earnings (regression test: *recording a salary
  payment does not duplicate earnings*).
- October salary paid in November counts as October earnings and as received *for October*.
- Only `completed` entries count; `pending`, `cancelled` and `reversed` are excluded.
- Identical entries (same source, item, type, period, date and amount) are rejected as duplicates
  unless the user explicitly confirms they are separate payments.

**Outstanding** = actual earned − received − deductions (per earning period).

## 7. Payment schedule

Accrual and payment are separate. Each salary/recurring source has an explicit, editable rule:

- day *N* of (accrual month + offset months) — clamped to short months (31 → 30/29/28);
- last day of (accrual month + offset);
- a manually entered date (temporary work, irregular payers).

Optional weekend/holiday adjustment moves the date to the previous or next working day. Statuses:
received (≥ expected), partially received, overdue (due date passed), due today, upcoming.
Bonuses and one-time items use their expected date. Non-cash benefits never create a cash
expectation.

## 8. Compensation items

Bonuses, incentives, benefits, allowances, reimbursements and one-time income keep expected amount
and date, actual amount and earned date, plus flags:

- `countsAsEarnings` — include in earnings totals;
- `includeInForecast` — include in forecasts (lets the user exclude a one-off from projections);
- `nonCash` — counts as earnings if flagged, but never as cash expected or received.

Expected counts in the period of the expected date; actual counts in the period of the earned date.

## 9. Forecasts (always labelled as estimates)

Month forecast per source:

- rule-based income: full-month accrual from the rules + adjustments;
- variable income: recorded actual if finalised; otherwise `max(actual so far, projection)` where
  the projection is the user's estimate or the average of the last 3 or 6 months that have actuals
  (per-source setting; falls back to the estimate);
- items: earned items + planned items marked for forecasting + future occurrences of recurring
  items (monthly/quarterly/yearly from their first date, skipped when a concrete item of the same
  type already exists that month).

Year forecast = recorded actuals for completed months + month forecasts for the current and future
months.

### What-if

Hypothetical changes (hike %, extra monthly income, one-time amount, change in weekly hours) are
applied to the baseline forecast without touching any records. Weekly hours convert to months with
365.25 / 7 / 12 ≈ 4.348 weeks per month.

## 10. Safety rules

- Percentage changes with a zero baseline display "—" instead of dividing by zero.
- Negative adjustments are allowed; other amounts must be positive and below 10¹⁵ minor units.
- Summaries are derived from authoritative records on every change; no cached totals can go stale.
