/// Exact rational number backed by [BigInt].
///
/// All authoritative money maths in EarnLens is done with [Fraction]s of
/// minor currency units (e.g. paise). Rounding happens only once, at the
/// presentation or persistence boundary, so repeated additions never drift.
class Fraction implements Comparable<Fraction> {
  factory Fraction(BigInt numerator, [BigInt? denominator]) {
    final den = denominator ?? BigInt.one;
    if (den == BigInt.zero) {
      throw ArgumentError('Fraction denominator must not be zero');
    }
    var n = numerator;
    var d = den;
    if (d.isNegative) {
      n = -n;
      d = -d;
    }
    final g = n.gcd(d);
    if (g > BigInt.one) {
      n = n ~/ g;
      d = d ~/ g;
    }
    return Fraction._(n, d);
  }

  const Fraction._(this.numerator, this.denominator);

  factory Fraction.fromInt(int value, [int denominator = 1]) =>
      Fraction(BigInt.from(value), BigInt.from(denominator));

  static final Fraction zero = Fraction._(BigInt.zero, BigInt.one);
  static final Fraction one = Fraction._(BigInt.one, BigInt.one);

  final BigInt numerator;
  final BigInt denominator;

  bool get isZero => numerator == BigInt.zero;
  bool get isNegative => numerator.isNegative;

  Fraction operator +(Fraction other) => Fraction(
        numerator * other.denominator + other.numerator * denominator,
        denominator * other.denominator,
      );

  Fraction operator -(Fraction other) => Fraction(
        numerator * other.denominator - other.numerator * denominator,
        denominator * other.denominator,
      );

  Fraction operator *(Fraction other) =>
      Fraction(numerator * other.numerator, denominator * other.denominator);

  Fraction operator /(Fraction other) {
    if (other.isZero) throw ArgumentError('Division by zero');
    return Fraction(numerator * other.denominator, denominator * other.numerator);
  }

  Fraction operator -() => Fraction._(-numerator, denominator);

  Fraction timesInt(int value) => Fraction(numerator * BigInt.from(value), denominator);

  Fraction divInt(int value) => Fraction(numerator, denominator * BigInt.from(value));

  Fraction abs() => isNegative ? -this : this;

  /// Rounds to the nearest integer using banker's rounding (half to even).
  BigInt roundHalfEven() {
    final q = numerator ~/ denominator; // truncates toward zero
    final r = numerator - q * denominator; // same sign as numerator
    final twiceR = r.abs() * BigInt.two;
    final cmp = twiceR.compareTo(denominator);
    if (cmp < 0) return q;
    final away = numerator.isNegative ? q - BigInt.one : q + BigInt.one;
    if (cmp > 0) return away;
    return q.isEven ? q : away;
  }

  /// Largest integer less than or equal to this value.
  BigInt floor() {
    final q = numerator ~/ denominator;
    if (numerator.isNegative && q * denominator != numerator) {
      return q - BigInt.one;
    }
    return q;
  }

  int roundToInt() => roundHalfEven().toInt();

  /// Renders the value with exactly [places] decimal places (half-even).
  String toDecimalString(int places) {
    final scale = BigInt.from(10).pow(places);
    final scaled = (this * Fraction(scale)).roundHalfEven();
    final negative = scaled.isNegative;
    final digits = scaled.abs().toString().padLeft(places + 1, '0');
    final intPart = digits.substring(0, digits.length - places);
    final frac = places == 0 ? '' : '.${digits.substring(digits.length - places)}';
    return '${negative ? '-' : ''}$intPart$frac';
  }

  double toDouble() => numerator / denominator;

  static Fraction sum(Iterable<Fraction> values) =>
      values.fold(Fraction.zero, (a, b) => a + b);

  static Fraction min(Fraction a, Fraction b) => a.compareTo(b) <= 0 ? a : b;
  static Fraction max(Fraction a, Fraction b) => a.compareTo(b) >= 0 ? a : b;

  @override
  int compareTo(Fraction other) =>
      (numerator * other.denominator).compareTo(other.numerator * denominator);

  bool operator <(Fraction other) => compareTo(other) < 0;
  bool operator <=(Fraction other) => compareTo(other) <= 0;
  bool operator >(Fraction other) => compareTo(other) > 0;
  bool operator >=(Fraction other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      other is Fraction &&
      other.numerator == numerator &&
      other.denominator == denominator;

  @override
  int get hashCode => Object.hash(numerator, denominator);

  @override
  String toString() => '$numerator/$denominator';
}
