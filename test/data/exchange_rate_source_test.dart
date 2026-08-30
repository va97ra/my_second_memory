import 'package:ez_data/ez_data.dart';
import 'package:flutter_test/flutter_test.dart';

const _body = '''
{
  "Date": "2026-08-30T11:30:00+03:00",
  "Valute": {
    "USD": {"CharCode": "USD", "Nominal": 1, "Value": 90.5},
    "JPY": {"CharCode": "JPY", "Nominal": 100, "Value": 62.0},
    "KRW": {"CharCode": "KRW", "Nominal": 1000, "Value": 65.0},
    "BAD": {"CharCode": "BAD", "Nominal": 0, "Value": 1.0}
  }
}
''';

void main() {
  test('the nominal is removed once, at parse time', () {
    final rates = parseCbrDaily(_body);

    expect(rates.base, 'RUB');
    expect(rates.rateOf('USD'), 90.5);
    expect(rates.rateOf('JPY'), 0.62);
    expect(rates.rateOf('KRW'), 0.065);
  });

  test('the rate date comes from the response, not from the clock', () {
    expect(parseCbrDaily(_body).date.toUtc(),
        DateTime.utc(2026, 8, 30, 8, 30));
  });

  test('a row with a zero nominal is skipped instead of dividing by zero', () {
    expect(parseCbrDaily(_body).knows('BAD'), isFalse);
  });

  test('a broken response is refused, not read as empty rates', () {
    expect(() => parseCbrDaily('not json'),
        throwsA(isA<ExchangeRateUnavailable>()));
    expect(() => parseCbrDaily('{"Date": "2026-08-30T11:30:00+03:00"}'),
        throwsA(isA<ExchangeRateUnavailable>()));
    expect(() => parseCbrDaily('{"Date": "x", "Valute": {}}'),
        throwsA(isA<ExchangeRateUnavailable>()));
  });
}
