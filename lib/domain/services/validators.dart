import '../../core/errors/app_exception.dart';
import '../models/enums.dart';
import '../models/income_source.dart';
import '../models/records.dart';

/// Domain validation shared by forms, repositories and imports.
class Validators {
  const Validators._();

  /// Upper bound for any single amount (₹10 trillion in paise) — guards
  /// against typos and integer overflow in aggregates.
  static const maxAmountMinor = 1000000000000000;

  static void source(IncomeSource s) {
    if (s.name.trim().isEmpty) throw const ValidationException('Name is required', field: 'name');
    if (s.name.length > 80) throw const ValidationException('Name is too long', field: 'name');
    if (s.endDate != null && s.endDate!.isBefore(s.startDate)) {
      throw const ValidationException('End date cannot be before the start date', field: 'endDate');
    }
    if (!s.schedule.isValid) {
      throw const ValidationException('Working schedule needs at least one day and an end time after the start time',
          field: 'schedule');
    }
    if (s.payDay < 1 || s.payDay > 31) throw const ValidationException('Pay day must be 1–31', field: 'payDay');
    if (s.payOffsetMonths < 0 || s.payOffsetMonths > 12) {
      throw const ValidationException('Payment delay must be 0–12 months', field: 'payOffsetMonths');
    }
    if (s.kind == IncomeKind.temporary && s.endDate == null) {
      throw const ValidationException('Temporary work needs an end date', field: 'endDate');
    }
    if (s.fixedTotalMinor != null) {
      if (s.kind != IncomeKind.temporary) {
        throw const ValidationException('A fixed total is only used for temporary work');
      }
      amount(s.fixedTotalMinor!, field: 'fixedTotal', allowZero: false);
    }
    if (s.takeHomeMinor != null) amount(s.takeHomeMinor!, field: 'takeHome');
  }

  static void revision(RateRevision r, IncomeSource s) {
    amount(r.amountMinor, field: 'amount');
    if (r.period == RatePeriod.hour && s.accrualPolicy != AccrualPolicy.workingDay) {
      throw const ValidationException('Hourly rates need the "working days only" policy so hours are defined',
          field: 'period');
    }
    if (s.kind == IncomeKind.variable && r.period == RatePeriod.hour) {
      throw const ValidationException('Use a monthly estimate for variable income', field: 'period');
    }
  }

  static void item(CompensationItem i) {
    if (i.title.trim().isEmpty) throw const ValidationException('Title is required', field: 'title');
    if (i.expectedMinor == null && i.actualMinor == null) {
      throw const ValidationException('Enter an expected or an actual amount', field: 'amount');
    }
    if (i.expectedMinor != null) amount(i.expectedMinor!, field: 'expected');
    if (i.actualMinor != null) {
      amount(i.actualMinor!, field: 'actual');
      if (i.earnedDate == null) throw const ValidationException('When was it earned?', field: 'earnedDate');
    }
    if (i.expectedMinor != null && i.expectedDate == null && i.earnedDate == null) {
      throw const ValidationException('Pick the expected date', field: 'expectedDate');
    }
  }

  static void ledger(LedgerEntry e) {
    if (e.type == LedgerType.adjustment) {
      if (e.amountMinor == 0) throw const ValidationException('Adjustment cannot be zero', field: 'amount');
      if (e.amountMinor.abs() > maxAmountMinor) throw const ValidationException('Amount is too large', field: 'amount');
    } else {
      amount(e.amountMinor, field: 'amount', allowZero: false);
    }
  }

  static void monthly(MonthlyRecord r) {
    for (final v in [r.originalEstimateMinor, r.revisedEstimateMinor, r.actualMinor]) {
      if (v != null) amount(v, field: 'amount');
    }
  }

  static void amount(int minor, {String? field, bool allowZero = true}) {
    if (minor < 0) throw ValidationException('Amount cannot be negative', field: field);
    if (!allowZero && minor == 0) throw ValidationException('Amount must be more than zero', field: field);
    if (minor > maxAmountMinor) throw ValidationException('Amount is too large', field: field);
  }
}
