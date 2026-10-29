import 'package:earnlens/core/date_time/local_date.dart';
import 'package:earnlens/domain/money/currency.dart';
import 'package:earnlens/domain/money/fraction.dart';
import 'package:earnlens/domain/money/money_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Fraction', () {
    test('normalises sign and reduces', () {
      final f = Fraction(BigInt.from(6), BigInt.from(-8));
      expect(f.numerator, BigInt.from(-3));
      expect(f.denominator, BigInt.from(4));
    });

    test('banker\'s rounding', () {
      expect(Fraction.fromInt(5, 2).roundToInt(), 2);
      expect(Fraction.fromInt(7, 2).roundToInt(), 4);
      expect(Fraction.fromInt(-5, 2).roundToInt(), -2);
      expect(Fraction.fromInt(-7, 2).roundToInt(), -4);
      expect(Fraction.fromInt(10, 3).roundToInt(), 3);
      expect(Fraction.fromInt(-10, 3).roundToInt(), -3);
    });

    test('decimal rendering', () {
      expect(Fraction.fromInt(1, 3).toDecimalString(4), '0.3333');
      expect(Fraction.fromInt(-1, 8).toDecimalString(2), '-0.12');
      expect(Fraction.fromInt(12345).toDecimalString(0), '12345');
    });

    test('floor', () {
      expect(Fraction.fromInt(-1, 2).floor(), BigInt.from(-1));
      expect(Fraction.fromInt(3, 2).floor(), BigInt.one);
    });

    test('division by zero throws', () {
      expect(() => Fraction.fromInt(1, 0), throwsArgumentError);
      expect(() => Fraction.one / Fraction.zero, throwsArgumentError);
    });
  });

  group('MoneyParser', () {
    test('parses decimal input to minor units without floats', () {
      expect(MoneyParser.parseMinor('35,000', Currency.inr), 3500000);
      expect(MoneyParser.parseMinor('0.1', Currency.inr), 10);
      expect(MoneyParser.parseMinor('1234.56', Currency.inr), 123456);
      expect(MoneyParser.parseMinor('.5', Currency.inr), 50);
    });

    test('rejects invalid values', () {
      expect(MoneyParser.parseMinor('', Currency.inr), isNull);
      expect(MoneyParser.parseMinor('abc', Currency.inr), isNull);
      expect(MoneyParser.parseMinor('1.234', Currency.inr), isNull);
      expect(MoneyParser.parseMinor('-5', Currency.inr), isNull);
      expect(MoneyParser.parseMinor('1.5', Currency.byCode('JPY')), isNull);
    });

    test('negative only when allowed', () {
      expect(MoneyParser.parseMinor('-5', Currency.inr, allowNegative: true), -500);
    });

    test('round-trips input formatting', () {
      expect(MoneyParser.toInput(3500000, Currency.inr), '35000');
      expect(MoneyParser.toInput(123450, Currency.inr), '1234.5');
      expect(MoneyParser.toInput(-10, Currency.inr), '-0.1');
    });

    test('percent to basis points', () {
      expect(MoneyParser.parsePercentBps('12.5'), 1250);
      expect(MoneyParser.parsePercentBps('-3'), -300);
      expect(MoneyParser.parsePercentBps('x'), isNull);
    });
  });

  group('LocalDate', () {
    test('leap years', () {
      expect(LocalDate.isLeapYear(2024), isTrue);
      expect(LocalDate.isLeapYear(1900), isFalse);
      expect(LocalDate.isLeapYear(2000), isTrue);
      expect(LocalDate.daysInMonth(2023, 2), 28);
      expect(LocalDate.daysInMonth(2024, 2), 29);
    });

    test('epoch day round trip across a wide range', () {
      for (var e = -50000; e < 50000; e += 137) {
        expect(LocalDate.fromEpochDay(e).epochDay, e);
      }
      expect(LocalDate(1970, 1, 1).epochDay, 0);
    });

    test('weekday', () {
      expect(LocalDate(2026, 10, 28).weekday, 3); // Wednesday
      expect(LocalDate(2024, 2, 29).weekday, 4); // Thursday
    });

    test('addMonths clamps the day', () {
      expect(LocalDate(2024, 1, 31).addMonths(1), LocalDate(2024, 2, 29));
      expect(LocalDate(2023, 1, 31).addMonths(1), LocalDate(2023, 2, 28));
      expect(LocalDate(2024, 12, 15).addMonths(1), LocalDate(2025, 1, 15));
    });

    test('rejects invalid dates', () {
      expect(() => LocalDate(2023, 2, 29), throwsArgumentError);
      expect(() => LocalDate(2024, 13, 1), throwsArgumentError);
    });

    test('YearMonth arithmetic', () {
      expect(YearMonth(2024, 12).next, YearMonth(2025, 1));
      expect(YearMonth(2024, 1).previous, YearMonth(2023, 12));
      expect(YearMonth(2024, 1).monthsUntil(YearMonth(2025, 3)), 14);
    });

    test('DateRange is half-open', () {
      final r = DateRange.month(YearMonth(2024, 2));
      expect(r.lengthInDays, 29);
      expect(r.contains(LocalDate(2024, 3, 1)), isFalse);
      expect(r.contains(LocalDate(2024, 2, 1)), isTrue);
    });
  });
}
