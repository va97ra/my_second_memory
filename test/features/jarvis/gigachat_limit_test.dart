import 'dart:convert';

import 'package:ez_core/ez_core.dart';
import 'package:ez_data/ez_data.dart';
import 'package:ezhednevnik_v2/src/features/jarvis/state/gigachat_limit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Остаток пакета GigaChat: полоска мерится от самого большого остатка, а
/// без остатка виден расход за месяц.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  GigaChatClient client(int status, Object body, {List<int>? spent}) =>
      GigaChatClient(
        authKey: 'Y2xpZW50LWlkOmNsaWVudC1zZWNyZXQ=',
        onUsage: spent?.add,
        connect: () async => MockClient((request) async {
          if (request.url.path.endsWith('/oauth')) {
            return http.Response(
                jsonEncode({'access_token': 'T', 'expires_at': 4102444800000}),
                200);
          }
          if (request.url.path.endsWith('/balance')) {
            return http.Response(jsonEncode(body), status);
          }
          return http.Response.bytes(
            utf8.encode(jsonEncode({
              'choices': [
                {
                  'message': {'role': 'assistant', 'content': 'Готов.'},
                },
              ],
              'usage': {'total_tokens': 42},
            })),
            200,
          );
        }),
      );

  test('остаток пакета своей модели', () async {
    final balance = await client(200, {
      'balance': [
        {'usage': 'embeddings', 'value': 1000},
        {'usage': 'GigaChat-2', 'value': 950000},
      ],
    }).balance();
    expect(balance, 950000);
  });

  test('Сбер остатка не дал — null, без ошибки', () async {
    expect(await client(403, {'message': 'forbidden'}).balance(), isNull);
  });

  test('каждый ответ сообщает расход', () async {
    final spent = <int>[];
    await client(200, const {}, spent: spent).check();
    expect(spent, [42]);
  });

  test('полоска — от самого большого остатка, расход копится за месяц',
      () async {
    var left = 1000;
    final limit = GigaChatLimitController(
      balance: () async => left,
      clock: () => DateTime(2026, 10, 9),
    );
    await limit.refresh();
    left = 250;
    // Чаще раза в полминуты не спрашивает — новый контроллер, как после
    // перезапуска, помнит прежний максимум.
    final later = GigaChatLimitController(
      balance: () async => left,
      clock: () => DateTime(2026, 10, 9, 0, 1),
    );
    await pumpEventQueue();
    await later.refresh();
    expect(later.state.left, 250);
    expect(later.state.share, 0.25);
    await later.spent(100);
    await later.spent(20);
    expect(later.state.spentThisMonth, 120);
  });

  test('остаток — точным числом: видно, как он тает после ответа', () {
    final strings = AppStrings(const Locale('ru'));
    expect(strings.gigaChatLeft(249987432),
        'GigaChat: осталось 249\u00A0987\u00A0432 токена');
    expect(strings.gigaChatLeft(250000000, spentThisMonth: 12568),
        'GigaChat: осталось 250\u00A0000\u00A0000 токенов · за месяц 12\u00A0568');
  });
}
