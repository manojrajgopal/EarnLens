import '../../../core/date_time/local_date.dart';

/// User-facing copy for each notification type. Amounts are omitted when
/// privacy mode is on so nothing sensitive appears on the lock screen.
class NotificationTemplates {
  const NotificationTemplates._();

  static (String, String) upcomingSalary(String source, LocalDate due, String? amount) => (
        'Payday coming up',
        amount == null ? '$source is expected on ${_d(due)}.' : '$source ($amount) is expected on ${_d(due)}.',
      );

  static (String, String) payday(String source, String? amount) => (
        'Expected payment today',
        amount == null
            ? '$source is due today. Record it once it arrives.'
            : '$source ($amount) is due today. Record it once it arrives.',
      );

  static (String, String) upcomingBonus(String title, LocalDate due) =>
      ('Bonus expected soon', '$title is expected on ${_d(due)}.');

  static (String, String) overdue(String title) =>
      ('Payment overdue', '$title has not been recorded as received. Mark it received or update the date.');

  static (String, String) temporaryEnding(String source, LocalDate end) =>
      ('Temporary work ending', '$source ends on ${_d(end)}. Earnings stop accruing after that day.');

  static (String, String) monthlyActual(String source, YearMonth month) =>
      ('How did ${_m(month)} go?', 'Enter the actual amount earned from $source in ${_m(month)}.');

  static (String, String) monthEnd(YearMonth month) =>
      ('Month-end review', 'Review ${_m(month)}: compare expected and actual earnings and record any missing income.');

  static (String, String) backup(int days) => (
        'Time for a backup',
        days < 0
            ? 'You have never backed up EarnLens. Your data only lives on this device.'
            : 'Your last backup was $days days ago. Back up to keep your history safe.',
      );

  static (String, String) summary(bool weekly, String? earned) => (
        weekly ? 'Your week in earnings' : 'Today in earnings',
        earned == null ? 'Open EarnLens to see what you have earned.' : 'Estimated earned this month so far: $earned.',
      );

  static (String, String) calendar(String title) => ('Reminder', title);

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static String _m(YearMonth m) => _months[m.month - 1];
  static String _d(LocalDate d) => '${d.day} ${_months[d.month - 1].substring(0, 3)}';
}
