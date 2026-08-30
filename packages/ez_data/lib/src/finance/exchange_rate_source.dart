import 'dart:convert';

import 'package:ez_domain/ez_domain.dart';
import 'package:http/http.dart' as http;

/// Откуда берутся курсы.
///
/// Источник отделён от кэша нарочно: он единственное место, которое знает про
/// сеть и про формат чужого ответа. Заменить ЦБ на другой источник — значит
/// написать второй такой класс, а не править экран и хранение.
abstract interface class ExchangeRateSource {
  Future<ExchangeRates> fetch();
}

/// Курсы Банка России. Ключа и авторизации не требует.
///
/// Берём JSON-зеркало вместо официального XML: официальный отдаёт
/// windows-1251, и ради него пришлось бы тащить разбор XML и перекодировку.
/// Цена выбора — зеркало стороннее и может пропасть; поэтому всякий отказ
/// сети оставляет приложение на последних известных курсах, а не пустым.
class CbrExchangeRateSource implements ExchangeRateSource {
  CbrExchangeRateSource({http.Client? client, Uri? endpoint})
      : _client = client ?? http.Client(),
        _endpoint = endpoint ?? Uri.parse(_defaultEndpoint);

  static const _defaultEndpoint = 'https://www.cbr-xml-daily.ru/daily_json.js';
  static const baseCurrency = 'RUB';

  final http.Client _client;
  final Uri _endpoint;

  @override
  Future<ExchangeRates> fetch() async {
    final response = await _client
        .get(_endpoint)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw ExchangeRateUnavailable('HTTP ${response.statusCode}');
    }
    return parseCbrDaily(utf8.decode(response.bodyBytes));
  }
}

/// Разбор ответа ЦБ. Вынесен из класса, чтобы проверяться без сети.
ExchangeRates parseCbrDaily(String body) {
  final Map<String, Object?> decoded;
  try {
    decoded = jsonDecode(body) as Map<String, Object?>;
  } catch (error) {
    throw ExchangeRateUnavailable('malformed response: $error');
  }
  final rawDate = decoded['Date'];
  final rawValute = decoded['Valute'];
  if (rawDate is! String || rawValute is! Map) {
    throw const ExchangeRateUnavailable('response has no Date or Valute');
  }
  final basePerUnit = <String, double>{};
  for (final entry in rawValute.entries) {
    final row = entry.value;
    if (row is! Map) continue;
    final nominal = row['Nominal'];
    final value = row['Value'];
    if (nominal is! num || value is! num || nominal <= 0) continue;
    final code = row['CharCode'] is String
        ? row['CharCode'] as String
        : entry.key.toString();
    // Номинал снимается здесь и больше нигде: сто иен и тысяча вон не должны
    // доезжать до правила пересчёта.
    basePerUnit[code] = value.toDouble() / nominal.toDouble();
  }
  if (basePerUnit.isEmpty) {
    throw const ExchangeRateUnavailable('response carries no rates');
  }
  return ExchangeRates(
    base: CbrExchangeRateSource.baseCurrency,
    date: DateTime.parse(rawDate).toLocal(),
    basePerUnit: basePerUnit,
  );
}

class ExchangeRateUnavailable implements Exception {
  const ExchangeRateUnavailable(this.reason);

  final String reason;

  @override
  String toString() => 'Exchange rates are unavailable: $reason';
}
