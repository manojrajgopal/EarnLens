import 'currency.dart';

/// Parses user-entered decimal amounts into integer minor units without
/// going through floating point.
class MoneyParser {
  const MoneyParser._();

  /// Returns null when [input] is not a valid amount for [currency].
  /// Accepts grouping separators (`,`, spaces, `_`) and an optional sign.
  static int? parseMinor(String input, Currency currency, {bool allowNegative = false}) {
    var s = input.trim().replaceAll(RegExp(r'[,\s_]'), '');
    if (s.isEmpty) return null;
    var negative = false;
    if (s.startsWith('-')) {
      if (!allowNegative) return null;
      negative = true;
      s = s.substring(1);
    } else if (s.startsWith('+')) {
      s = s.substring(1);
    }
    if (!RegExp(r'^\d+(\.\d*)?$|^\.\d+$').hasMatch(s)) return null;
    final parts = s.split('.');
    final whole = parts[0].isEmpty ? '0' : parts[0];
    var frac = parts.length > 1 ? parts[1] : '';
    if (frac.length > currency.minorDigits) return null;
    frac = frac.padRight(currency.minorDigits, '0');
    if (whole.length > 13) return null; // guards against overflow
    final value = int.parse(whole) * currency.minorPerMajor + (frac.isEmpty ? 0 : int.parse(frac));
    return negative ? -value : value;
  }

  /// Formats minor units as a plain decimal string suitable for an input field.
  static String toInput(int minor, Currency currency) {
    final negative = minor < 0;
    final abs = minor.abs();
    final whole = abs ~/ currency.minorPerMajor;
    final frac = abs % currency.minorPerMajor;
    final fracStr = currency.minorDigits == 0
        ? ''
        : '.${frac.toString().padLeft(currency.minorDigits, '0')}';
    final trimmed = fracStr.replaceFirst(RegExp(r'\.?0+$'), '');
    return '${negative ? '-' : ''}$whole$trimmed';
  }

  /// Parses a percentage such as "12.5" into basis points (1250).
  static int? parsePercentBps(String input) {
    final s = input.trim().replaceAll('%', '');
    if (!RegExp(r'^-?\d+(\.\d{0,2})?$').hasMatch(s)) return null;
    final negative = s.startsWith('-');
    final body = negative ? s.substring(1) : s;
    final parts = body.split('.');
    final frac = (parts.length > 1 ? parts[1] : '').padRight(2, '0');
    final v = int.parse(parts[0]) * 100 + int.parse(frac);
    return negative ? -v : v;
  }
}
