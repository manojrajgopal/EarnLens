/// Currency metadata used for storage and formatting.
///
/// Amounts are always stored as integer minor units (paise, cents, ...).
class Currency {
  const Currency(this.code, this.symbol, this.minorDigits, this.name);

  final String code;
  final String symbol;
  final int minorDigits;
  final String name;

  int get minorPerMajor {
    var v = 1;
    for (var i = 0; i < minorDigits; i++) {
      v *= 10;
    }
    return v;
  }

  static const inr = Currency('INR', '₹', 2, 'Indian Rupee');

  static const supported = <Currency>[
    inr,
    Currency('USD', '\$', 2, 'US Dollar'),
    Currency('EUR', '€', 2, 'Euro'),
    Currency('GBP', '£', 2, 'British Pound'),
    Currency('AED', 'AED', 2, 'UAE Dirham'),
    Currency('SGD', 'S\$', 2, 'Singapore Dollar'),
    Currency('AUD', 'A\$', 2, 'Australian Dollar'),
    Currency('CAD', 'C\$', 2, 'Canadian Dollar'),
    Currency('JPY', '¥', 0, 'Japanese Yen'),
  ];

  static Currency byCode(String code) => supported.firstWhere(
        (c) => c.code == code,
        orElse: () => Currency(code, code, 2, code),
      );

  @override
  bool operator ==(Object other) => other is Currency && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => code;
}
