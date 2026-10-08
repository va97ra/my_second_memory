import 'package:http/http.dart' as http;

/// Соединение не открылось: TLS или сеть отказали до HTTP.
class GigaChatConnectionException implements Exception {
  const GigaChatConnectionException(this.message);

  final String message;
}

/// В вебе своему корневому сертификату не доверишь: браузер проверяет его
/// сам. Отказ браузера доходит до клиента как отсутствие связи.
Future<http.Client> connectGigaChat() async => http.Client();
