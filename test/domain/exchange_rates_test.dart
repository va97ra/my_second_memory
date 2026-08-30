import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final rates = ExchangeRates(
    base: 'RUB',
    date: DateTime(2026, 8, 30),
    basePerUnit: const {'USD': 90.0, 'EUR': 100.0, 'JPY': 0.6},
  );

  test('the base currency converts to itself one to one', () {
    expect(rates.convert(amount: 500, from: 'RUB', to: 'RUB'), 500);
  });

  test('conversion to the base multiplies by the unit price', () {
    expect(rates.convert(amount: 2, from: 'USD', to: 'RUB'), 180);
  });

  test('conversion from the base divides by the unit price', () {
    expect(rates.convert(amount: 180, from: 'RUB', to: 'USD'), 2);
  });

  test('a pair without the base goes through it', () {
    expect(rates.convert(amount: 100, from: 'EUR', to: 'USD'),
        closeTo(111.111, 0.001));
  });

  test('an unknown currency answers nothing instead of zero', () {
    expect(rates.convert(amount: 10, from: 'RUB', to: 'XXX'), isNull);
    expect(rates.knows('XXX'), isFalse);
    expect(rates.knows('RUB'), isTrue);
  });

  test('rates survive a round trip through json', () {
    final restored = ExchangeRates.fromJson(rates.toJson());

    expect(restored.base, 'RUB');
    expect(restored.date, rates.date);
    expect(restored.rateOf('JPY'), 0.6);
  });
}
