import '../../core/date_time/local_date.dart';
import '../models/enums.dart';
import '../models/income_source.dart';

/// Everything the accrual engine needs to know about one income source.
class SourceRules {
  SourceRules({
    required this.source,
    required List<RateRevision> revisions,
    List<SourcePause> pauses = const [],
    List<DayOverride> overrides = const [],
  })  : revisions = _sorted(revisions.where((r) => r.sourceId == source.id)),
        pauses = pauses.where((p) => p.sourceId == source.id).toList(),
        _overrides = {
          for (final o in overrides)
            if (o.sourceId == null || o.sourceId == source.id) o.date: o.type,
        };

  final IncomeSource source;
  final List<RateRevision> revisions;
  final List<SourcePause> pauses;
  final Map<LocalDate, DayOverrideType> _overrides;
  final Map<YearMonth, int> _workingDaysCache = {};
  int? _fixedTotalDaysCache;

  static List<RateRevision> _sorted(Iterable<RateRevision> list) {
    final l = list.toList()
      ..sort((a, b) {
        final c = a.effectiveFrom.compareTo(b.effectiveFrom);
        return c != 0 ? c : a.createdAt.compareTo(b.createdAt);
      });
    return l;
  }

  WorkSchedule get schedule => source.schedule;

  /// The revision in force on [d]; later-created revisions win on the same date.
  RateRevision? revisionOn(LocalDate d) {
    RateRevision? current;
    for (final r in revisions) {
      if (r.effectiveFrom.isAfter(d)) break;
      current = r;
    }
    return current;
  }

  bool inEmploymentRange(LocalDate d) {
    if (d.isBefore(source.startDate)) return false;
    final end = source.endDate;
    return end == null || !d.isAfter(end);
  }

  bool isPaused(LocalDate d) => pauses.any((p) => p.covers(d));

  DayOverrideType? overrideOn(LocalDate d) => _overrides[d];

  Set<LocalDate> get holidayDates => {
        for (final e in _overrides.entries)
          if (e.value == DayOverrideType.holiday) e.key,
      };

  bool isHoliday(LocalDate d) => _overrides[d] == DayOverrideType.holiday;

  bool isUnpaidLeave(LocalDate d) => _overrides[d] == DayOverrideType.unpaidLeave;

  /// A scheduled weekday that is not a paid holiday.
  bool isWorkingDay(LocalDate d) => schedule.weekdays.contains(d.weekday) && !isHoliday(d);

  /// Working days in the whole calendar month (unpaid leave included, paid
  /// holidays excluded). This is the working-day policy denominator.
  int workingDaysInMonth(YearMonth m) => _workingDaysCache.putIfAbsent(m, () {
        var count = 0;
        for (final d in DateRange.month(m).days) {
          if (isWorkingDay(d)) count++;
        }
        return count;
      });

  /// Denominator for spreading a fixed total over the engagement.
  int fixedTotalDays() => _fixedTotalDaysCache ??= () {
        final end = source.endDate;
        if (end == null) return 0;
        final range = DateRange(source.startDate, end.addDays(1));
        if (source.fixedTotalAccrual == FixedTotalAccrual.spreadWorkingDays) {
          return range.days.where(isWorkingDay).length;
        }
        return range.lengthInDays;
      }();

  /// Whether accrual is limited to the work window of working days.
  bool get usesWorkingTime {
    if (source.usesFixedTotal) {
      return source.fixedTotalAccrual == FixedTotalAccrual.spreadWorkingDays;
    }
    return source.accrualPolicy == AccrualPolicy.workingDay;
  }
}
