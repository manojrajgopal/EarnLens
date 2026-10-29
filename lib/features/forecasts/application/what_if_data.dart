import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/date_time/local_date.dart';
import '../../../domain/calculation/rate_calculator.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/income_source.dart';

/// A source together with a current rate in minor units.
class RatedSource {
  const RatedSource(this.source, this.rateMinor);
  final IncomeSource source;
  final int rateMinor;
}

class WhatIfBaseline {
  const WhatIfBaseline({
    required this.month,
    required this.monthly,
    required this.annual,
    required this.salarySources,
    required this.hourlySources,
  });

  final YearMonth month;

  /// Forecast for the current month.
  final int monthly;

  /// Sum of the forecasts for the current and next eleven months.
  final int annual;

  /// Salary sources with their current monthly pay.
  final List<RatedSource> salarySources;

  /// Sources paid by the hour with their working-time hourly rate.
  final List<RatedSource> hourlySources;
}

final whatIfBaselineProvider = Provider.autoDispose<WhatIfBaseline>((ref) {
  final snap = ref.watch(snapshotProvider);
  final calc = ref.watch(earningsCalculatorProvider);
  final forecasts = ref.watch(forecastCalculatorProvider);
  final currency = ref.watch(currencyProvider).code;
  final today = ref.watch(todayProvider);
  final nowMicros = ref.watch(clockProvider).now().microsecondsSinceEpoch;
  final current = today.yearMonth;

  final monthly = forecasts.forMonth(snap, current, nowMicros, currencyCode: currency).total;
  var annual = 0;
  for (var i = 0; i < 12; i++) {
    annual += forecasts.forMonth(snap, current.addMonths(i), nowMicros, currencyCode: currency).total;
  }

  final salary = <RatedSource>[];
  final hourly = <RatedSource>[];
  for (final s in snap.sources) {
    if (s.currencyCode != currency || s.status != SourceStatus.active || !s.kind.accruesContinuously) continue;
    final rules = snap.rules[s.id]!;
    if (s.kind == IncomeKind.salary) {
      final m = calc.rates.rate(rules, EarningUnit.month, today).roundToInt();
      if (m > 0) salary.add(RatedSource(s, m));
    }
    if (rules.revisionOn(today)?.period == RatePeriod.hour) {
      final h = calc.rates.rate(rules, EarningUnit.hour, today, basis: RateBasis.workingTime).roundToInt();
      if (h > 0) hourly.add(RatedSource(s, h));
    }
  }

  return WhatIfBaseline(
    month: current,
    monthly: monthly,
    annual: annual,
    salarySources: salary,
    hourlySources: hourly,
  );
});

/// Parses a decimal with up to two places into hundredths ("12.5" → 1250).
/// Accepts a leading sign when [allowNegative] is true.
int? parseHundredths(String input, {bool allowNegative = false}) {
  final t = input.trim().replaceAll('−', '-').replaceAll(',', '.');
  final m = RegExp(r'^([+-]?)(\d{1,6})(?:\.(\d{1,2}))?$').firstMatch(t);
  if (m == null) return null;
  final negative = m[1] == '-';
  if (negative && !allowNegative) return null;
  final frac = (m[3] ?? '').padRight(2, '0');
  final value = int.parse(m[2]!) * 100 + int.parse(frac);
  return negative ? -value : value;
}
