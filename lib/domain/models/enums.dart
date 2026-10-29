/// Enumerations shared across the domain. Each value has a stable [name]
/// that is persisted in the database and in backups — never rename values.
library;

enum IncomeKind {
  /// Employment salary with continuous accrual and a payment rule.
  salary,

  /// Fixed recurring income (rent received, retainer) with continuous accrual.
  recurring,

  /// Temporary or part-time work bounded by start and end dates.
  temporary,

  /// Variable income (business, freelance) tracked by monthly estimate vs actual.
  variable,

  /// A single payment that is earned once.
  oneTime;

  bool get accruesContinuously => this == salary || this == recurring || this == temporary;

  String get label => switch (this) {
        salary => 'Salary',
        recurring => 'Fixed recurring',
        temporary => 'Temporary / part-time',
        variable => 'Variable income',
        oneTime => 'One-time income',
      };

  String get description => switch (this) {
        salary => 'Monthly pay from an employer, earned every day you are employed.',
        recurring => 'A fixed amount every period, like rent or a retainer.',
        temporary => 'Work with a start and end date, paid by the hour, day or as a fixed total.',
        variable => 'Income that changes every month, like a business or freelancing.',
        oneTime => 'A single payment, earned once.',
      };
}

enum IncomeCategory {
  salary,
  freelance,
  partTime,
  business,
  rental,
  consulting,
  commission,
  investment,
  other,
  custom;

  String get label => switch (this) {
        salary => 'Salary',
        freelance => 'Freelance',
        partTime => 'Part-time job',
        business => 'Business',
        rental => 'Rental income',
        consulting => 'Consulting',
        commission => 'Commission',
        investment => 'Investments / dividends',
        other => 'Other',
        custom => 'Custom',
      };
}

enum SourceStatus {
  active,
  paused,
  ended,
  archived;

  String get label => switch (this) {
        active => 'Active',
        paused => 'Paused',
        ended => 'Ended',
        archived => 'Archived',
      };
}

enum AccrualPolicy {
  /// Pay is spread evenly over every calendar day (and every second) of the month.
  calendarDay,

  /// Pay is spread over configured working days and working hours only.
  workingDay;

  String get label => switch (this) {
        calendarDay => 'Every calendar day',
        workingDay => 'Working days only',
      };
}

enum RatePeriod {
  hour,
  day,
  week,
  month,
  year;

  String get label => switch (this) {
        hour => 'per hour',
        day => 'per day',
        week => 'per week',
        month => 'per month',
        year => 'per year',
      };
}

enum RevisionChangeType {
  initial,
  hike,
  decrease,
  correction,
  estimateUpdate;

  String get label => switch (this) {
        initial => 'Starting rate',
        hike => 'Hike',
        decrease => 'Decrease',
        correction => 'Correction',
        estimateUpdate => 'Estimate update',
      };
}

enum FixedTotalAccrual {
  /// Total spread evenly over every calendar day of the engagement.
  spreadCalendarDays,

  /// Total spread over working days of the engagement.
  spreadWorkingDays,

  /// Nothing is earned until the engagement's last day is complete.
  onCompletion;

  String get label => switch (this) {
        spreadCalendarDays => 'Spread over all days',
        spreadWorkingDays => 'Spread over working days',
        onCompletion => 'Earned on completion',
      };
}

enum PayRule {
  /// Paid on [payDay] of the accrual month + offset months.
  dayOfMonth,

  /// Paid on the last day of the accrual month + offset months.
  lastDayOfMonth,

  /// Paid on a manually entered date (temporary work, irregular payers).
  manual;

  String get label => switch (this) {
        dayOfMonth => 'On a day of the month',
        lastDayOfMonth => 'On the last day of the month',
        manual => 'I will enter the date',
      };
}

enum WeekendAdjust {
  none,
  previousBusinessDay,
  nextBusinessDay;

  String get label => switch (this) {
        none => 'No adjustment',
        previousBusinessDay => 'Move to previous working day',
        nextBusinessDay => 'Move to next working day',
      };
}

enum ForecastMethod {
  estimate,
  average3,
  average6;

  String get label => switch (this) {
        estimate => 'Use my estimate',
        average3 => 'Average of last 3 months',
        average6 => 'Average of last 6 months',
      };
}

enum DayOverrideType {
  /// Paid non-working day — excluded from the working-day denominator.
  holiday,

  /// Unpaid leave — counted in the denominator but earns nothing.
  unpaidLeave;

  String get label => switch (this) {
        holiday => 'Paid holiday',
        unpaidLeave => 'Unpaid leave',
      };
}

enum CompensationType {
  oneTimeIncome,
  joiningBonus,
  annualBonus,
  performanceIncentive,
  recurringBonus,
  benefit,
  allowance,
  reimbursement,
  other;

  String get label => switch (this) {
        oneTimeIncome => 'One-time income',
        joiningBonus => 'Joining bonus',
        annualBonus => 'Annual bonus',
        performanceIncentive => 'Performance incentive',
        recurringBonus => 'Recurring bonus',
        benefit => 'Benefit',
        allowance => 'Allowance',
        reimbursement => 'Reimbursement',
        other => 'Other compensation',
      };
}

enum Recurrence {
  none,
  monthly,
  quarterly,
  yearly;

  int get months => switch (this) {
        none => 0,
        monthly => 1,
        quarterly => 3,
        yearly => 12,
      };

  String get label => switch (this) {
        none => 'Does not repeat',
        monthly => 'Every month',
        quarterly => 'Every quarter',
        yearly => 'Every year',
      };
}

enum LedgerType {
  /// Money actually received. Never adds to earnings.
  received,

  /// A detailed earning entry (invoice, sale) for variable/one-off income.
  earned,

  /// Signed correction to earnings for a period (e.g. retroactive arrears).
  adjustment,

  /// Amount withheld from pay (tax, provident fund).
  deduction,

  /// Refund or reversal of money previously received.
  reversal;

  String get label => switch (this) {
        received => 'Payment received',
        earned => 'Income earned',
        adjustment => 'Earnings adjustment',
        deduction => 'Deduction',
        reversal => 'Refund / reversal',
      };
}

enum LedgerStatus {
  /// Recorded as planned/expected; not counted in totals.
  pending,

  /// Confirmed and counted.
  completed,
  cancelled,
  reversed;

  bool get counts => this == completed;

  String get label => switch (this) {
        pending => 'Pending',
        completed => 'Completed',
        cancelled => 'Cancelled',
        reversed => 'Reversed',
      };
}

enum CalendarEventType {
  reminder,
  expectedIncome,
  note;

  String get label => switch (this) {
        reminder => 'Reminder',
        expectedIncome => 'Expected income',
        note => 'Note',
      };
}

T enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  if (name == null) return fallback;
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}
