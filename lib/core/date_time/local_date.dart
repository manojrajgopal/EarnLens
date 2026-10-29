/// A calendar date without time or timezone ("2026-10-28").
///
/// Financial events (effective dates, pay dates, earned dates) are stored as
/// [LocalDate]s so they are never reinterpreted when the device timezone
/// changes.
class LocalDate implements Comparable<LocalDate> {
  LocalDate(this.year, this.month, this.day) {
    if (month < 1 || month > 12 || day < 1 || day > daysInMonth(year, month)) {
      throw ArgumentError('Invalid date $year-$month-$day');
    }
  }

  factory LocalDate.fromDateTime(DateTime dt) => LocalDate(dt.year, dt.month, dt.day);

  /// Parses `yyyy-MM-dd`.
  factory LocalDate.parse(String iso) {
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(iso.trim());
    if (m == null) throw FormatException('Invalid date', iso);
    return LocalDate(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
  }

  static LocalDate? tryParse(String? iso) {
    if (iso == null) return null;
    try {
      return LocalDate.parse(iso);
    } on Object {
      return null;
    }
  }

  final int year;
  final int month;
  final int day;

  static bool isLeapYear(int year) =>
      (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

  static int daysInMonth(int year, int month) {
    const days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if (month == 2 && isLeapYear(year)) return 29;
    return days[month - 1];
  }

  /// Days since 1970-01-01 (proleptic Gregorian), computed without timezones.
  int get epochDay {
    // Algorithm from Howard Hinnant's days_from_civil.
    final y = month <= 2 ? year - 1 : year;
    final era = (y >= 0 ? y : y - 399) ~/ 400;
    final yoe = y - era * 400;
    final mp = (month + 9) % 12;
    final doy = (153 * mp + 2) ~/ 5 + day - 1;
    final doe = yoe * 365 + yoe ~/ 4 - yoe ~/ 100 + doy;
    return era * 146097 + doe - 719468;
  }

  factory LocalDate.fromEpochDay(int z0) {
    final z = z0 + 719468;
    final era = (z >= 0 ? z : z - 146096) ~/ 146097;
    final doe = z - era * 146097;
    final yoe = (doe - doe ~/ 1460 + doe ~/ 36524 - doe ~/ 146096) ~/ 365;
    final y = yoe + era * 400;
    final doy = doe - (365 * yoe + yoe ~/ 4 - yoe ~/ 100);
    final mp = (5 * doy + 2) ~/ 153;
    final d = doy - (153 * mp + 2) ~/ 5 + 1;
    final m = mp < 10 ? mp + 3 : mp - 9;
    return LocalDate(m <= 2 ? y + 1 : y, m, d);
  }

  /// ISO weekday: Monday = 1 ... Sunday = 7.
  int get weekday {
    final w = (epochDay + 3) % 7; // 1970-01-01 was a Thursday (index 3)
    return (w < 0 ? w + 7 : w) + 1;
  }

  LocalDate addDays(int days) => LocalDate.fromEpochDay(epochDay + days);

  /// Adds months, clamping the day to the target month's length.
  LocalDate addMonths(int months) {
    final total = year * 12 + (month - 1) + months;
    final y = total ~/ 12;
    final m = total % 12 + 1;
    final d = day.clamp(1, daysInMonth(y, m));
    return LocalDate(y, m, d);
  }

  int daysUntil(LocalDate other) => other.epochDay - epochDay;

  YearMonth get yearMonth => YearMonth(year, month);

  bool isBefore(LocalDate other) => compareTo(other) < 0;
  bool isAfter(LocalDate other) => compareTo(other) > 0;

  LocalDate min(LocalDate other) => isBefore(other) ? this : other;
  LocalDate max(LocalDate other) => isAfter(other) ? this : other;

  DateTime toDateTime() => DateTime(year, month, day);

  String toIso() =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  @override
  int compareTo(LocalDate other) => epochDay.compareTo(other.epochDay);

  @override
  bool operator ==(Object other) =>
      other is LocalDate && other.year == year && other.month == month && other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIso();
}

/// A calendar month ("2026-10").
class YearMonth implements Comparable<YearMonth> {
  YearMonth(this.year, this.month) {
    if (month < 1 || month > 12) throw ArgumentError('Invalid month $month');
  }

  factory YearMonth.parse(String s) {
    final m = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(s.trim());
    if (m == null) throw FormatException('Invalid month', s);
    return YearMonth(int.parse(m[1]!), int.parse(m[2]!));
  }

  final int year;
  final int month;

  LocalDate get firstDay => LocalDate(year, month, 1);
  LocalDate get lastDay => LocalDate(year, month, lengthInDays);

  /// Exclusive end: the first day of the next month.
  LocalDate get endExclusive => next.firstDay;

  int get lengthInDays => LocalDate.daysInMonth(year, month);

  YearMonth get next => addMonths(1);
  YearMonth get previous => addMonths(-1);

  YearMonth addMonths(int n) {
    final total = year * 12 + (month - 1) + n;
    return YearMonth(total ~/ 12, total % 12 + 1);
  }

  int monthsUntil(YearMonth other) => (other.year * 12 + other.month) - (year * 12 + month);

  bool contains(LocalDate d) => d.year == year && d.month == month;

  String toIso() => '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';

  @override
  int compareTo(YearMonth other) => (year * 12 + month).compareTo(other.year * 12 + other.month);

  bool isBefore(YearMonth other) => compareTo(other) < 0;
  bool isAfter(YearMonth other) => compareTo(other) > 0;

  @override
  bool operator ==(Object other) => other is YearMonth && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => toIso();
}

/// Half-open date range `[start, endExclusive)`.
class DateRange {
  DateRange(this.start, this.endExclusive) {
    if (endExclusive.isBefore(start)) {
      throw ArgumentError('Range end before start: $start..$endExclusive');
    }
  }

  factory DateRange.month(YearMonth m) => DateRange(m.firstDay, m.endExclusive);

  factory DateRange.year(int year) => DateRange(LocalDate(year, 1, 1), LocalDate(year + 1, 1, 1));

  final LocalDate start;
  final LocalDate endExclusive;

  int get lengthInDays => start.daysUntil(endExclusive);

  bool contains(LocalDate d) => !d.isBefore(start) && d.isBefore(endExclusive);

  DateRange? intersect(DateRange other) {
    final s = start.max(other.start);
    final e = endExclusive.min(other.endExclusive);
    return s.isBefore(e) ? DateRange(s, e) : null;
  }

  Iterable<LocalDate> get days sync* {
    for (var d = start; d.isBefore(endExclusive); d = d.addDays(1)) {
      yield d;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.start == start && other.endExclusive == endExclusive;

  @override
  int get hashCode => Object.hash(start, endExclusive);

  @override
  String toString() => '[$start, $endExclusive)';
}
