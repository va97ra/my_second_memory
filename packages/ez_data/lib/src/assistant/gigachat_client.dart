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
    this.retryPause = const Duration(seconds: 1),
    this.quickFailure = const Duration(seconds: 5),
    this.onUsage,
    DateTime Function()? clock,
  })  : _connect = connect ?? connectGigaChat,
        _clock = clock ?? DateTime.now;

  /// GigaChat Lite: самый большой бесплатный пакет и самый быстрый.
  static const defaultModel = 'GigaChat-2';

  /// Похоже ли [value] на ключ авторизации. Ключ — base64 от пары
  /// «идентификатор:секрет»: латиница, цифры, `+ / =`, без пробелов. Текст
  /// с кириллицей ключом быть не может — его даже нельзя отправить в
  /// заголовке запроса.
  static bool looksLikeAuthKey(String value) =>
      RegExp(r'^[A-Za-z0-9+/_-]{20,}={0,2}$').hasMatch(value.trim());

  static final _tokenUrl =
      Uri.parse('https://ngw.devices.sberbank.ru:9443/api/v2/oauth');
  static final _chatUrl =
      Uri.parse('https://gigachat.devices.sberbank.ru/api/v1/chat/completions');
  static final _balanceUrl =
      Uri.parse('https://gigachat.devices.sberbank.ru/api/v1/balance');

  final String authKey;
  final String model;
  final Duration timeout;

  /// Пауза перед повтором после сбоя, который проходит сам.
  final Duration retryPause;

  /// Отказ быстрее этого — сбой, который проходит сам, и его повторяют.
  /// Сервер, думавший дольше и всё же отказавший, второй раз думает столько
  /// же: 12 октября 2026 Сбер отвечал 500 через 20 с, и с повтором Джарвис
  /// молчал 42 с.
  final Duration quickFailure;

  /// Сколько токенов ушло на ответ — GigaChat сообщает это в каждом.
  final void Function(int tokens)? onUsage;
  final Future<http.Client> Function() _connect;
  final DateTime Function() _clock;
  http.Client? _client;
  String? _token;
  DateTime? _tokenUntil;

  Future<http.Client> _http() async => _client ??= await _connect();

  /// Токен доступа — с запасом в минуту до конца его жизни.
  Future<String> token() async {
    if (!looksLikeAuthKey(authKey)) {
      throw const GigaChatException(
          'Сохранённый ключ GigaChat не похож на настоящий. Вставьте ключ '
          'заново в настройках Джарвиса.');
    }
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
  /// вызов функции (`function_call`), — и почему она остановилась
  /// (`finish_reason`; `length` — текст оборвал лимит токенов).
  ///
  /// [callFunctions] false — модель видит [functions], но вызвать их уже не
  /// может и отвечает словами (`function_call: none`).
  Future<Map<String, dynamic>> chat(
    List<Map<String, dynamic>> messages, {
    List<Map<String, dynamic>> functions = const [],
    bool callFunctions = true,
  }) async {
    final body = jsonEncode({
      'model': model,
      'messages': messages,
      if (functions.isNotEmpty) 'functions': functions,
      if (functions.isNotEmpty)
        'function_call': callFunctions ? 'auto' : 'none',
      'temperature': 0.3,
      'max_tokens': 600,
    });
    final asked = Stopwatch()..start();
    var response = await _ask(body);
    // Сбой, который проходит сам, — повторить один раз, а не обрывать
    // разговор: токен умер раньше срока, «подождите» или сервер сбоит.
    if ((response.statusCode == 401 ||
            response.statusCode == 429 ||
            response.statusCode >= 500) &&
        asked.elapsed < quickFailure) {
      if (response.statusCode == 401) _token = null;
      await Future<void>.delayed(
          response.statusCode == 429 ? retryPause * 2 : retryPause);
      response = await _ask(body);
    }
    switch (response.statusCode) {
      case 200:
        break;
      case 401:
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
    final spent = (json['usage'] as Map?)?['total_tokens'];
    if (spent is num) onUsage?.call(spent.toInt());
    final choices = json['choices'] as List? ?? const [];
    if (choices.isEmpty) {
      throw const GigaChatException('GigaChat ничего не ответил.');
    }
    final choice = choices.first as Map;
    return {
      ...Map<String, dynamic>.from(choice['message'] as Map),
      if (choice['finish_reason'] != null)
        'finish_reason': choice['finish_reason'],
    };
  }

  Future<http.Response> _ask(String body) async {
    final bearer = await token();
    return _send(() async => (await _http()).post(
          _chatUrl,
          headers: {
            'Authorization': 'Bearer $bearer',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: body,
        ));
  }

  /// Сколько токенов модели [model] осталось в пакете; null — Сбер не
  /// сказал (так бывает на бесплатном пакете) или нет связи.
  Future<int?> balance() async {
    final http.Response response;
    try {
      final bearer = await token();
      response = await _send(() async => (await _http()).get(
            _balanceUrl,
            headers: {
              'Authorization': 'Bearer $bearer',
              'Accept': 'application/json',
            },
          ));
    } on GigaChatException {
      return null;
    }
    if (response.statusCode != 200) return null;
    final json = jsonDecode(utf8.decode(response.bodyBytes));
    final packages = json is Map ? json['balance'] : null;
    if (packages is! List) return null;
    int? valueOf(bool Function(String usage) matches) {
      for (final package in packages) {
        if (package is! Map) continue;
        final usage = '${package['usage']}';
        final value = package['value'];
        if (matches(usage) && value is num) return value.toInt();
      }
      return null;
    }

    // Пакет называется по модели; у Lite встречается и старое имя без «-2».
    return valueOf((usage) => usage == model) ??
        valueOf((usage) => usage == model.replaceFirst('-2', ''));
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
  ///
  /// Оборванное соединение пробуется ещё раз — новым. Телефон переходит с
  /// Wi-Fi на мобильную сеть, и сохранённое соединение умирает молча:
  /// первый же запрос по нему падал, и связь с GigaChat «слетала».
  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await _once(request);
    } on GigaChatException catch (failure) {
      if (!failure.offline || failure.message == _silent) rethrow;
      _client?.close();
      _client = null;
      await Future<void>.delayed(retryPause);
      return _once(request);
    }
  }

  static const _silent = 'GigaChat не отвечает.';

  Future<http.Response> _once(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(timeout);
    } on TimeoutException {
      // Ответа ждали полминуты — второй раз ждать столько же незачем.
      throw const GigaChatException(_silent, offline: true);
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
