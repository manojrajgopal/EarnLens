import 'package:intl/intl.dart';

import '../../domain/money/currency.dart';
import '../../domain/money/fraction.dart';

/// Locale-aware money formatting (Indian lakh/crore grouping for en_IN).
/// Only formats — never used for arithmetic.
class MoneyFormatter {
  MoneyFormatter(this.locale, this.currency)
      : _group = NumberFormat.decimalPattern(locale),
        _compact = NumberFormat.compactCurrency(locale: locale, symbol: currency.symbol, decimalDigits: 1);

  final String locale;
  final Currency currency;
  final NumberFormat _group;
  final NumberFormat _compact;

  /// Formats integer minor units, e.g. 3500000 → "₹35,000.00".
  String minor(int value, {bool showMinor = true, bool compact = false}) {
    if (compact && value.abs() >= 100000 * currency.minorPerMajor) {
      return _compact.format(value / currency.minorPerMajor);
    }
    return fraction(Fraction.fromInt(value), decimals: showMinor ? currency.minorDigits : 0);
  }

  /// Formats an exact fraction of minor units with [decimals] places of the
  /// major unit (half-even), e.g. per-second rates "₹0.0135".
  String fraction(Fraction minorUnits, {int? decimals}) {
    final places = decimals ?? currency.minorDigits;
    final major = minorUnits.divInt(currency.minorPerMajor);
    final s = major.toDecimalString(places);
    final negative = s.startsWith('-');
    final body = negative ? s.substring(1) : s;
    final parts = body.split('.');
    final whole = _group.format(int.parse(parts[0]));
    final frac = parts.length > 1 ? '.${parts[1]}' : '';
    final isZero = RegExp(r'^[0.]+$').hasMatch(body);
    return '${negative && !isZero ? '−' : ''}${currency.symbol}$whole$frac';
  }

  /// Signed variant used for variances: "+₹4,500.00" / "−₹200.00".
  String signed(int value) => value > 0 ? '+${minor(value)}' : minor(value);

  static const hidden = '••••••';
}

/// Percentage change with safe handling of zero denominators.
String? percentChange(int from, int to) {
  if (from == 0) return null;
  final pct = (to - from) * 1000 ~/ from.abs();
  final sign = pct > 0 ? '+' : (pct < 0 ? '−' : '');
  final abs = pct.abs();
  return '$sign${abs ~/ 10}.${abs % 10}%';
}
