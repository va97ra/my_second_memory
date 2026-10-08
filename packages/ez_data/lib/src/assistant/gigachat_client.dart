import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'gigachat_connection.dart';

/// Почему GigaChat не ответил — словами для человека.
class GigaChatException implements Exception {
  const GigaChatException(this.message, {this.offline = false});

  final String message;

  /// Связи нет или сервер занят: Джарвис отвечает правилами, без нейросети.
  final bool offline;

  @override
  String toString() => message;
}

/// GigaChat (Сбер) — нейросеть Джарвиса для свободного разговора.
///
/// Ключ авторизации человек берёт сам в личном кабинете developers.sber.ru
/// (физлица: scope `GIGACHAT_API_PERS`, бесплатный пакет на год). Токен
/// живёт 30 минут и обновляется заранее. Сервера подписаны сертификатом
/// Минцифры, которому Android не доверяет, поэтому ему доверяется только в
/// этом соединении ([connectGigaChat]).
///
/// Перенесено из MemoryVoice, где проверено на телефоне владельца.
class GigaChatClient {
  GigaChatClient({
    required this.authKey,
    this.model = defaultModel,
    Future<http.Client> Function()? connect,
    this.timeout = const Duration(seconds: 30),
    DateTime Function()? clock,
  })  : _connect = connect ?? connectGigaChat,
        _clock = clock ?? DateTime.now;

  /// GigaChat Lite: самый большой бесплатный пакет и самый быстрый.
  static const defaultModel = 'GigaChat-2';

  static final _tokenUrl =
      Uri.parse('https://ngw.devices.sberbank.ru:9443/api/v2/oauth');
  static final _chatUrl =
      Uri.parse('https://gigachat.devices.sberbank.ru/api/v1/chat/completions');

  final String authKey;
  final String model;
  final Duration timeout;
  final Future<http.Client> Function() _connect;
  final DateTime Function() _clock;
  http.Client? _client;
  String? _token;
  DateTime? _tokenUntil;

  Future<http.Client> _http() async => _client ??= await _connect();

  /// Токен доступа — с запасом в минуту до конца его жизни.
  Future<String> token() async {
    final known = _token;
    final until = _tokenUntil;
    if (known != null && until != null && _clock().isBefore(until)) {
      return known;
    }
    final response = await _send(() async => (await _http()).post(
          _tokenUrl,
          headers: {
            'Authorization': 'Basic ${authKey.trim()}',
            'RqUID': _uuid(),
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'application/json',
          },
          body: 'scope=GIGACHAT_API_PERS',
        ));
    if (response.statusCode == 400 || response.statusCode == 401) {
      throw const GigaChatException(
          'Ключ GigaChat не подошёл. Проверьте его в настройках Джарвиса.');
    }
    if (response.statusCode != 200) {
      throw GigaChatException(
        'GigaChat не дал доступ (ошибка ${response.statusCode}).',
        offline: response.statusCode >= 500,
      );
    }
    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final expires = json['expires_at'];
    _token = json['access_token'] as String;
    _tokenUntil = (expires is int
            ? DateTime.fromMillisecondsSinceEpoch(expires)
            : _clock().add(const Duration(minutes: 30)))
        .subtract(const Duration(minutes: 1));
    return _token!;
  }

  /// Один запрос к модели. Возвращает её сообщение: текст (`content`) или
  /// вызов функции (`function_call`).
  Future<Map<String, dynamic>> chat(
    List<Map<String, dynamic>> messages, {
    List<Map<String, dynamic>> functions = const [],
  }) async {
    final bearer = await token();
    final response = await _send(() async => (await _http()).post(
          _chatUrl,
          headers: {
            'Authorization': 'Bearer $bearer',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'model': model,
            'messages': messages,
            if (functions.isNotEmpty) 'functions': functions,
            if (functions.isNotEmpty) 'function_call': 'auto',
            'temperature': 0.3,
            'max_tokens': 600,
          }),
        ));
    switch (response.statusCode) {
      case 200:
        break;
      case 401:
        // Токен умер раньше срока: следующий запрос возьмёт новый.
        _token = null;
        throw const GigaChatException(
            'GigaChat не принял доступ. Попробуйте ещё раз.');
      case 402:
        throw const GigaChatException(
            'Бесплатные токены GigaChat закончились.');
      case 429:
        throw const GigaChatException(
          'GigaChat просит подождать: слишком много запросов.',
          offline: true,
        );
      default:
        throw GigaChatException(
          'GigaChat ответил ошибкой ${response.statusCode}.',
          offline: response.statusCode >= 500,
        );
    }
    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final choices = json['choices'] as List? ?? const [];
    if (choices.isEmpty) {
      throw const GigaChatException('GigaChat ничего не ответил.');
    }
    return Map<String, dynamic>.from(
        (choices.first as Map)['message'] as Map);
  }

  /// Проверка ключа и связи: короткий вопрос — короткий ответ.
  Future<String> check() async {
    final message = await chat([
      {'role': 'user', 'content': 'Ответь одним словом: готов.'},
    ]);
    return (message['content'] as String? ?? '').trim();
  }

  void close() => _client?.close();

  /// Отказ сети — не поломка: о нём говорят словами, а Джарвис продолжает
  /// отвечать правилами.
  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(timeout);
    } on TimeoutException {
      throw const GigaChatException('GigaChat не отвечает.', offline: true);
    } on http.ClientException {
      throw const GigaChatException('Нет связи с GigaChat.', offline: true);
    } on GigaChatConnectionException catch (error) {
      throw GigaChatException(error.message, offline: true);
    }
  }

  static String _uuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex =
        bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
