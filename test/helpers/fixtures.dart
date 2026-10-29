import 'package:earnlens/core/date_time/local_date.dart';
import 'package:earnlens/domain/calculation/accrual_engine.dart';
import 'package:earnlens/domain/calculation/financial_calendar.dart';
import 'package:earnlens/domain/models/enums.dart';
import 'package:earnlens/domain/models/income_source.dart';
import 'package:earnlens/domain/models/records.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

bool _tzReady = false;

FinancialCalendar calendarFor(String zone) {
  if (!_tzReady) {
    tzdata.initializeTimeZones();
    _tzReady = true;
  }
  return FinancialCalendar(tz.getLocation(zone));
}

AccrualEngine engineFor([String zone = 'Asia/Kolkata']) => AccrualEngine(calendarFor(zone));

final fixedCreated = DateTime.utc(2024, 1, 1);

LocalDate d(int y, int m, int day) => LocalDate(y, m, day);

/// Instant (micros) of a local wall-clock time in [cal]'s zone.
int at(FinancialCalendar cal, int y, int m, int day, [int hour = 0, int minute = 0]) =>
    tz.TZDateTime(cal.location, y, m, day, hour, minute).microsecondsSinceEpoch;

IncomeSource source({
  String id = 's1',
  IncomeKind kind = IncomeKind.salary,
  LocalDate? start,
  LocalDate? end,
  AccrualPolicy policy = AccrualPolicy.calendarDay,
  WorkSchedule schedule = const WorkSchedule(),
  PayRule payRule = PayRule.dayOfMonth,
  int payDay = 1,
  int payOffsetMonths = 1,
  WeekendAdjust weekendAdjust = WeekendAdjust.none,
  int? fixedTotal,
  FixedTotalAccrual fixedTotalAccrual = FixedTotalAccrual.spreadCalendarDays,
  ForecastMethod forecastMethod = ForecastMethod.estimate,
  String currency = 'INR',
  LocalDate? expectedPayDate,
}) =>
    IncomeSource(
      id: id,
      name: 'Source $id',
      kind: kind,
      category: IncomeCategory.salary,
      currencyCode: currency,
      startDate: start ?? d(2020, 1, 1),
      endDate: end,
      accrualPolicy: policy,
      schedule: schedule,
      payRule: payRule,
      payDay: payDay,
      payOffsetMonths: payOffsetMonths,
      weekendAdjust: weekendAdjust,
      fixedTotalMinor: fixedTotal,
      fixedTotalAccrual: fixedTotalAccrual,
      forecastMethod: forecastMethod,
      expectedPayDate: expectedPayDate,
      createdAt: fixedCreated,
      updatedAt: fixedCreated,
    );

int _revSeq = 0;

RateRevision rev(
  String sourceId,
  LocalDate from,
  int amountMinor, {
  RatePeriod period = RatePeriod.month,
  RevisionChangeType type = RevisionChangeType.initial,
  DateTime? createdAt,
}) =>
    RateRevision(
      id: 'r${_revSeq++}',
      sourceId: sourceId,
      effectiveFrom: from,
      amountMinor: amountMinor,
      period: period,
      changeType: type,
      createdAt: createdAt ?? fixedCreated,
    );

int _ledgerSeq = 0;

LedgerEntry ledger(
  String sourceId,
  LedgerType type,
  int amount,
  YearMonth period,
  LocalDate date, {
  LedgerStatus status = LedgerStatus.completed,
  String? itemId,
}) =>
    LedgerEntry(
      id: 'l${_ledgerSeq++}',
      sourceId: sourceId,
      itemId: itemId,
      type: type,
      amountMinor: amount,
      currencyCode: 'INR',
      periodMonth: period,
      date: date,
      status: status,
      createdAt: fixedCreated,
      updatedAt: fixedCreated,
    );

/// ₹ to paise.
int inr(num rupees) => (rupees * 100).round();
