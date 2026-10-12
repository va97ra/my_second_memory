import 'dart:convert';

import 'package:ez_data/ez_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Сбои, которые проходят сами, GigaChat переживает одним повтором:
/// разговор не обрывается из-за умершего соединения, токена или «подождите».
void main() {
  const key = 'Y2xpZW50LWlkOmNsaWVudC1zZWNyZXQ=';

  http.Response answer() => http.Response.bytes(
        utf8.encode(jsonEncode({
          'choices': [
            {
              'message': {'role': 'assistant', 'content': 'Готов.'},
            },
          ],
        })),
        200,
      );

  http.Response token() => http.Response(
      jsonEncode({'access_token': 'T', 'expires_at': 4102444800000}), 200);

  /// Сервер отвечает заготовками по очереди; [connections] — сколько раз
  /// открывали соединение, [tokens] — сколько раз брали токен.
  ({GigaChatClient client, List<int> connections, List<int> tokens}) server(
      List<Object> chatReplies,
      {Duration delay = Duration.zero}) {
    final connections = <int>[];
    final tokens = <int>[];
    final replies = [...chatReplies];
    final client = GigaChatClient(
      authKey: key,
      retryPause: Duration.zero,
      quickFailure: const Duration(milliseconds: 30),
      connect: () async {
        connections.add(connections.length);
        return MockClient((request) async {
          if (request.url.path.endsWith('/oauth')) {
            tokens.add(tokens.length);
            return token();
          }
          await Future<void>.delayed(delay);
          final next = replies.removeAt(0);
          if (next is Exception) throw next;
          return next as http.Response;
        });
      },
    );
    return (client: client, connections: connections, tokens: tokens);
  }

  test('соединение умерло — новое, и разговор продолжается', () async {
    final s = server([http.ClientException('Connection closed'), answer()]);
    expect(await s.client.check(), 'Готов.');
    expect(s.connections, hasLength(2), reason: 'старое соединение брошено');
  });

  test('«подождите» и сбой сервера — один повтор', () async {
    expect(await server([http.Response('{}', 429), answer()]).client.check(),
        'Готов.');
    expect(await server([http.Response('{}', 503), answer()]).client.check(),
        'Готов.');
  });

  test('сбой после долгого раздумья не повторяется', () async {
    // С телефона владельца, 12 октября 2026: Сбер думал по 20 с и отвечал
    // 500, повтор думал столько же — Джарвис молчал 42 с вместо 20.
    final s = server([http.Response('{}', 500), answer()],
        delay: const Duration(milliseconds: 60));
    await expectLater(
      s.client.check(),
      throwsA(isA<GigaChatException>()
          .having((error) => error.message, 'message', contains('500'))),
    );
  });

  test('токен умер раньше срока — новый токен и повтор', () async {
    final s = server([http.Response('{}', 401), answer()]);
    expect(await s.client.check(), 'Готов.');
    expect(s.tokens, hasLength(2));
  });

  test('не прошло и со второго раза — понятная причина', () async {
    final s = server([http.Response('{}', 429), http.Response('{}', 429)]);
    expect(
      s.client.check(),
      throwsA(isA<GigaChatException>()
          .having((error) => error.message, 'message', contains('подождать'))),
    );
  });
}
