import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('дюйм читается дробью', () {
    test('целое, дробь и смешанное число', () {
      expect(formatInchFraction(2), '2″');
      expect(formatInchFraction(0.75), '3/4″');
      expect(formatInchFraction(1.5), '1 1/2″');
      expect(formatInchFraction(0), '0″');
    });

    test('дробь сокращается до знаменателя, которым меряют', () {
      expect(formatInchFraction(0.5), '1/2″');
      expect(formatInchFraction(0.125), '1/8″');
      expect(formatInchFraction(0.0625), '1/16″');
    });

    test('округление до шестнадцатой помечается знаком «≈»', () {
      final inches = UnitConverter.convert(
        category: UnitCategory.length,
        fromUnitId: 'm',
        toUnitId: 'inch',
        value: 1,
      );
      expect(formatInchFraction(inches), '≈39 3/8″');
      // Ровная дробь знака не получает: 3/4 дюйма — это ровно 3/4 дюйма.
      expect(formatInchFraction(0.75), isNot(startsWith('≈')));
    });

    test('минус остаётся у числа, а не у нуля', () {
      expect(formatInchFraction(-0.75), '-3/4″');
      expect(formatInchFraction(-0.001), '≈0″');
    });

    test('нечисло не притворяется размером', () {
      expect(formatInchFraction(double.nan), '—');
      expect(formatInchFraction(double.infinity), '—');
    });
  });

  group('дробь в поле ввода', () {
    test('читается так, как её пишут на фитинге', () {
      expect(parseFractionalNumber('3/4'), 0.75);
      expect(parseFractionalNumber('1 1/2'), 1.5);
      expect(parseFractionalNumber('-1 1/2'), -1.5);
      expect(parseFractionalNumber(' 1/16 '), 0.0625);
    });

    test('обычное число разбирается прежним правилом', () {
      expect(parseFractionalNumber('1,5'), 1.5);
      expect(parseFractionalNumber('12'), 12);
    });

    test('деление на ноль и мусор числом не становятся', () {
      expect(parseFractionalNumber('1/0'), isNull);
      expect(parseFractionalNumber('половина'), isNull);
      expect(parseFractionalNumber(''), isNull);
    });
  });
}
