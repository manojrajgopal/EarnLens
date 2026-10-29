import '../money/fraction.dart';

/// A hypothetical change previewed by the what-if calculator. Nothing here
/// touches persisted records.
sealed class WhatIfChange {
  const WhatIfChange();
}

/// Percentage hike on a source's current monthly earnings.
class HikePercent extends WhatIfChange {
  const HikePercent({required this.currentMonthlyMinor, required this.percentBps, this.monthsRemaining = 12});
  final int currentMonthlyMinor;
  final int percentBps;
  final int monthsRemaining;
}

/// Additional monthly income (new part-time job, more business revenue).
class ExtraMonthly extends WhatIfChange {
  const ExtraMonthly({required this.monthlyMinor, this.monthsRemaining = 12});
  final int monthlyMinor;
  final int monthsRemaining;
}

/// A single additional payment.
class OneTimeAmount extends WhatIfChange {
  const OneTimeAmount(this.amountMinor);
  final int amountMinor;
}

/// Change in weekly hours for hourly work.
class HoursChange extends WhatIfChange {
  const HoursChange({
    required this.hourlyRateMinor,
    required this.weeklyHoursDelta,
    this.monthsRemaining = 12,
  });
  final int hourlyRateMinor;

  /// Hours per week added (positive) or removed (negative), in hundredths.
  final int weeklyHoursDelta;
  final int monthsRemaining;
}

class WhatIfResult {
  const WhatIfResult({
    required this.baselineMonthly,
    required this.newMonthly,
    required this.baselineAnnual,
    required this.newAnnual,
  });

  final int baselineMonthly;
  final int newMonthly;
  final int baselineAnnual;
  final int newAnnual;

  int get monthlyDelta => newMonthly - baselineMonthly;
  int get annualDelta => newAnnual - baselineAnnual;
}

class WhatIfCalculator {
  const WhatIfCalculator._();

  /// Average weeks per month used to convert weekly hours (365.25 / 7 / 12).
  static final Fraction weeksPerMonth = Fraction.fromInt(36525, 8400);

  /// [baselineMonthly] is the forecast for a typical month; [baselineAnnual]
  /// the forecast for the next twelve months.
  static WhatIfResult apply({
    required int baselineMonthly,
    required int baselineAnnual,
    required List<WhatIfChange> changes,
  }) {
    var monthly = Fraction.fromInt(baselineMonthly);
    var annual = Fraction.fromInt(baselineAnnual);
    for (final c in changes) {
      switch (c) {
        case HikePercent(:final currentMonthlyMinor, :final percentBps, :final monthsRemaining):
          final delta = Fraction.fromInt(currentMonthlyMinor) * Fraction.fromInt(percentBps, 10000);
          monthly += delta;
          annual += delta.timesInt(monthsRemaining);
        case ExtraMonthly(:final monthlyMinor, :final monthsRemaining):
          monthly += Fraction.fromInt(monthlyMinor);
          annual += Fraction.fromInt(monthlyMinor).timesInt(monthsRemaining);
        case OneTimeAmount(:final amountMinor):
          annual += Fraction.fromInt(amountMinor);
        case HoursChange(:final hourlyRateMinor, :final weeklyHoursDelta, :final monthsRemaining):
          final delta = Fraction.fromInt(hourlyRateMinor) * Fraction.fromInt(weeklyHoursDelta, 100) * weeksPerMonth;
          monthly += delta;
          annual += delta.timesInt(monthsRemaining);
      }
    }
    return WhatIfResult(
      baselineMonthly: baselineMonthly,
      newMonthly: monthly.roundToInt(),
      baselineAnnual: baselineAnnual,
      newAnnual: annual.roundToInt(),
    );
  }
}
