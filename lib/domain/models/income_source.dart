import '../../core/date_time/local_date.dart';
import 'enums.dart';

/// Working pattern used by working-day accrual and hourly/minute rates.
class WorkSchedule {
  const WorkSchedule({
    this.weekdays = const {1, 2, 3, 4, 5},
    this.startMinute = 9 * 60,
    this.endMinute = 18 * 60,
  });

  /// ISO weekdays (Mon = 1 ... Sun = 7) that are working days.
  final Set<int> weekdays;

  /// Start of the working window in minutes after local midnight.
  final int startMinute;

  /// Exclusive end of the working window in minutes after local midnight.
  final int endMinute;

  int get workingMinutesPerDay => endMinute - startMinute;

  int get weekdayMask => weekdays.fold(0, (m, d) => m | (1 << (d - 1)));

  static Set<int> weekdaysFromMask(int mask) => {
        for (var d = 1; d <= 7; d++)
          if (mask & (1 << (d - 1)) != 0) d,
      };

  bool get isValid =>
      weekdays.isNotEmpty &&
      startMinute >= 0 &&
      endMinute <= 24 * 60 &&
      endMinute > startMinute;

  WorkSchedule copyWith({Set<int>? weekdays, int? startMinute, int? endMinute}) => WorkSchedule(
        weekdays: weekdays ?? this.weekdays,
        startMinute: startMinute ?? this.startMinute,
        endMinute: endMinute ?? this.endMinute,
      );

  @override
  bool operator ==(Object other) =>
      other is WorkSchedule &&
      other.weekdayMask == weekdayMask &&
      other.startMinute == startMinute &&
      other.endMinute == endMinute;

  @override
  int get hashCode => Object.hash(weekdayMask, startMinute, endMinute);
}

/// An income source such as a salary, a rental, a temporary job or a business.
class IncomeSource {
  const IncomeSource({
    required this.id,
    this.accountId = '',
    required this.name,
    required this.kind,
    required this.category,
    required this.currencyCode,
    required this.startDate,
    required this.createdAt,
    required this.updatedAt,
    this.customCategory,
    this.status = SourceStatus.active,
    this.endDate,
    this.accrualPolicy = AccrualPolicy.calendarDay,
    this.schedule = const WorkSchedule(),
    this.payRule = PayRule.dayOfMonth,
    this.payDay = 1,
    this.payOffsetMonths = 1,
    this.weekendAdjust = WeekendAdjust.none,
    this.expectedPayDate,
    this.fixedTotalMinor,
    this.fixedTotalAccrual = FixedTotalAccrual.spreadCalendarDays,
    this.forecastMethod = ForecastMethod.estimate,
    this.employer,
    this.takeHomeMinor,
    this.notes,
    this.colorIndex = 0,
    this.isSample = false,
    this.sortOrder = 0,
  });

  final String id;

  /// Owning individual account. Stamped by the account-scoped repository on
  /// insert (any value passed in is replaced); always set on loaded records.
  final String accountId;
  final String name;
  final IncomeKind kind;
  final IncomeCategory category;
  final String? customCategory;
  final SourceStatus status;
  final String currencyCode;

  /// First eligible day (joining date / project start), inclusive.
  final LocalDate startDate;

  /// Last eligible day (last working day / project end), inclusive.
  final LocalDate? endDate;

  final AccrualPolicy accrualPolicy;
  final WorkSchedule schedule;

  final PayRule payRule;

  /// Day of month for [PayRule.dayOfMonth]; clamped to the month length.
  final int payDay;

  /// 0 = paid in the accrual month, 1 = following month, 2 = two months later...
  final int payOffsetMonths;
  final WeekendAdjust weekendAdjust;

  /// Used with [PayRule.manual].
  final LocalDate? expectedPayDate;

  /// Fixed total compensation for temporary work (instead of a rate).
  final int? fixedTotalMinor;
  final FixedTotalAccrual fixedTotalAccrual;

  final ForecastMethod forecastMethod;
  final String? employer;
  final int? takeHomeMinor;
  final String? notes;
  final int colorIndex;

  /// True for optional sample data the user explicitly enabled.
  final bool isSample;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get categoryLabel =>
      category == IncomeCategory.custom && (customCategory?.isNotEmpty ?? false)
          ? customCategory!
          : category.label;

  /// Exclusive end of eligibility, or null when open-ended.
  LocalDate? get endExclusive => endDate?.addDays(1);

  DateRange eligibleRange(LocalDate fallbackEnd) =>
      DateRange(startDate, (endExclusive ?? fallbackEnd).max(startDate));

  bool get usesFixedTotal => kind == IncomeKind.temporary && fixedTotalMinor != null;

  IncomeSource copyWith({
    String? name,
    SourceStatus? status,
    LocalDate? endDate,
    bool clearEndDate = false,
    int? sortOrder,
    DateTime? updatedAt,
  }) =>
      IncomeSource(
        id: id,
        accountId: accountId,
        name: name ?? this.name,
        kind: kind,
        category: category,
        customCategory: customCategory,
        status: status ?? this.status,
        currencyCode: currencyCode,
        startDate: startDate,
        endDate: clearEndDate ? null : (endDate ?? this.endDate),
        accrualPolicy: accrualPolicy,
        schedule: schedule,
        payRule: payRule,
        payDay: payDay,
        payOffsetMonths: payOffsetMonths,
        weekendAdjust: weekendAdjust,
        expectedPayDate: expectedPayDate,
        fixedTotalMinor: fixedTotalMinor,
        fixedTotalAccrual: fixedTotalAccrual,
        forecastMethod: forecastMethod,
        employer: employer,
        takeHomeMinor: takeHomeMinor,
        notes: notes,
        colorIndex: colorIndex,
        isSample: isSample,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// A rate (or, for variable income, a default monthly estimate) that is
/// effective from a date until the next revision. Revisions are never
/// overwritten when pay changes; a new revision is added instead.
class RateRevision {
  const RateRevision({
    required this.id,
    this.accountId = '',
    required this.sourceId,
    required this.effectiveFrom,
    required this.amountMinor,
    required this.period,
    required this.changeType,
    required this.createdAt,
    this.percentBps,
    this.note,
  });

  final String id;

  /// Owning individual account. Stamped by the account-scoped repository on
  /// insert (any value passed in is replaced); always set on loaded records.
  final String accountId;
  final String sourceId;
  final LocalDate effectiveFrom;
  final int amountMinor;
  final RatePeriod period;
  final RevisionChangeType changeType;

  /// Optional percentage change in basis points (1250 = 12.5%), informational.
  final int? percentBps;
  final String? note;
  final DateTime createdAt;
}

/// A period during which a source is paused and earns nothing.
class SourcePause {
  const SourcePause({
    required this.id,
    this.accountId = '',
    required this.sourceId,
    required this.start,
    this.endExclusive,
  });

  final String id;

  /// Owning individual account. Stamped by the account-scoped repository on
  /// insert (any value passed in is replaced); always set on loaded records.
  final String accountId;
  final String sourceId;
  final LocalDate start;

  /// Null while the pause is ongoing.
  final LocalDate? endExclusive;

  bool covers(LocalDate d) =>
      !d.isBefore(start) && (endExclusive == null || d.isBefore(endExclusive!));
}

/// A holiday or unpaid-leave day affecting working-day accrual.
class DayOverride {
  const DayOverride({
    required this.id,
    this.accountId = '',
    required this.date,
    required this.type,
    this.sourceId,
    this.note,
  });

  final String id;

  /// Owning individual account. Stamped by the account-scoped repository on
  /// insert (any value passed in is replaced); always set on loaded records.
  final String accountId;

  /// Null applies to every working-day source.
  final String? sourceId;
  final LocalDate date;
  final DayOverrideType type;
  final String? note;
}
