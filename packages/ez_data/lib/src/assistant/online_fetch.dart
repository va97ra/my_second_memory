import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Справка из сети не получена — словами, понятными и человеку, и
/// нейросети, которая перескажет причину.
class OnlineException implements Exception {
  const OnlineException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Запросы справок Джарвиса.
///
/// Таймаут короткий: часть сервисов режут мобильные операторы (у владельца
/// на МТС не открываются api.open-meteo.com и Википедия), и ждать их нельзя
/// — лучше честно сказать «недоступно» и ответить по-другому. Источники
/// бесплатные, без ключей; в сеть уходит только сам вопрос — город, слово,
/// тема, — а записи остаются на устройстве.
class OnlineFetch {
  OnlineFetch({http.Client? client, this.timeout = const Duration(seconds: 6)})
      : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  static const _headers = {
    'User-Agent': 'Ezhednevnik/1.2 (personal assistant)',
  };

  Future<String> text(Uri url) async {
    final http.Response response;
    try {
      response = await _client.get(url, headers: _headers).timeout(timeout);
    } on TimeoutException {
      throw const OnlineException('Интернет отвечает слишком долго');
    } on http.ClientException {
      throw const OnlineException('Нет интернета');
    }
    if (response.statusCode != 200) {
      throw OnlineException(
          'Сервис ответил ошибкой ${response.statusCode}, попробуйте позже');
    }
    return utf8.decode(response.bodyBytes);
  }

  Future<Object?> json(Uri url) async {
    final body = await text(url);
    try {
      return jsonDecode(body);
    } on FormatException {
      throw const OnlineException('Сервис прислал непонятный ответ');
    }
  }

  void close() => _client.close();
}
