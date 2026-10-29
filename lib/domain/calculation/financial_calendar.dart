import 'package:timezone/timezone.dart' as tz;

import '../../core/date_time/local_date.dart';

/// Maps calendar dates to absolute instants in the user's *financial*
/// timezone (a stored setting, not the device timezone).
///
/// Instants are represented as microseconds since the Unix epoch (UTC), so a
/// change of device timezone never changes a calculation result.
class FinancialCalendar {
  FinancialCalendar(this.location);

  final tz.Location location;

  String get timezoneName => location.name;

  int dayStartMicros(LocalDate d) =>
      tz.TZDateTime(location, d.year, d.month, d.day).microsecondsSinceEpoch;

  /// The instant at [minuteOfDay] minutes after local midnight of [d].
  /// 1440 yields the start of the next day.
  int localTimeMicros(LocalDate d, int minuteOfDay) {
    if (minuteOfDay >= 24 * 60) return dayStartMicros(d.addDays(1));
    return tz.TZDateTime(location, d.year, d.month, d.day, minuteOfDay ~/ 60, minuteOfDay % 60)
        .microsecondsSinceEpoch;
  }

  LocalDate dateOf(int micros) {
    final t = tz.TZDateTime.fromMicrosecondsSinceEpoch(location, micros);
    return LocalDate(t.year, t.month, t.day);
  }

  LocalDate today(DateTime now) => dateOf(now.microsecondsSinceEpoch);

  YearMonth monthOf(DateTime now) => today(now).yearMonth;
}
