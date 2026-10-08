import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Соединение не открылось: TLS или сеть отказали до HTTP.
class GigaChatConnectionException implements Exception {
  const GigaChatConnectionException(this.message);

  final String message;
}

const _certificate =
    'packages/ez_data/assets/certs/russian_trusted_root_ca.pem';

/// Соединение, которое доверяет корневому сертификату Минцифры — и только
/// оно: остальные соединения приложения про этот сертификат не знают.
/// Сертификат взят с gosuslugi.ru/crt, действует до 2032 года.
Future<http.Client> connectGigaChat() async {
  final context = SecurityContext(withTrustedRoots: true);
  final pem = await rootBundle.load(_certificate);
  context.setTrustedCertificatesBytes(
      pem.buffer.asUint8List(pem.offsetInBytes, pem.lengthInBytes));
  final client = HttpClient(context: context)
    ..connectionTimeout = const Duration(seconds: 10);
  return _GuardedClient(IOClient(client));
}

/// Отказ TLS приходит не `ClientException`, а исключением `dart:io`: здесь
/// он получает понятное имя, чтобы клиент сказал «нет связи», а не упал.
class _GuardedClient extends http.BaseClient {
  _GuardedClient(this._inner);

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    try {
      return await _inner.send(request);
    } on HandshakeException {
      throw const GigaChatConnectionException(
          'Не удалось защищённо соединиться с GigaChat.');
    } on SocketException {
      throw const GigaChatConnectionException('Нет связи с GigaChat.');
    }
  }

  @override
  void close() => _inner.close();
}
