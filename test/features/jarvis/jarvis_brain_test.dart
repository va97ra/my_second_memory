import 'dart:convert';

import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart' show ShiftSchedule;
import 'package:ezhednevnik_v2/src/app/local_storage_scope_provider.dart';
import 'package:ezhednevnik_v2/src/features/jarvis/state/jarvis_brain.dart';
import 'package:ezhednevnik_v2/src/features/jarvis/state/jarvis_brain_providers.dart';
import 'package:ezhednevnik_v2/src/features/jarvis/state/jarvis_controller.dart';
import 'package:ezhednevnik_v2/src/features/jarvis/state/jarvis_message.dart';
import 'package:ezhednevnik_v2/src/features/jarvis/state/jarvis_online.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/memory_items.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/recurrence.dart';
import 'package:ezhednevnik_v2/src/features/security/security.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/shift_schedules.dart';
import 'package:ezhednevnik_v2/src/shared/state/notification_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/memory_items_test_support.dart';
import '../../support/widget_test_harness.dart';

/// Ключ настоящего вида: base64 от «идентификатор:секрет».
const _key = 'Y2xpZW50LWlkOmNsaWVudC1zZWNyZXQ=';

/// Подставной GigaChat: выдаёт токен и заготовленные ответы модели по
/// очереди, запоминая, что ему прислали.
class _FakeGigaChat {
  final replies = <Map<String, dynamic>>[];
  final requests = <Map<String, dynamic>>[];
  int tokenStatus = 200;

  late final client = MockClient((request) async {
    if (request.url.path.endsWith('/oauth')) {
      expect(request.headers['Authorization'], 'Basic $_key');
      expect(request.body, 'scope=GIGACHAT_API_PERS');
      if (tokenStatus != 200) return http.Response('{}', tokenStatus);
      return http.Response(
          jsonEncode({
            'access_token': 'TOKEN',
            'expires_at': DateTime(2100).millisecondsSinceEpoch,
          }),
          200);
    }
    requests.add(jsonDecode(request.body) as Map<String, dynamic>);
    return http.Response.bytes(
      utf8.encode(jsonEncode({
        'choices': [
          {'message': replies.removeAt(0)},
        ],
      })),
      200,
      headers: {'content-type': 'application/json'},
    );
  });
}

void main() {
  useTestEnvironment();
  // Среда, 7 октября 2099, 14:00.
  final now = DateTime(2099, 10, 7, 14);
  late _FakeGigaChat server;

  Future<ProviderContainer> start({bool withKey = true}) async {
    server = _FakeGigaChat();
    final container = ProviderContainer(overrides: [
      localStorageScopeFactoryProvider
          .overrideWithValue(TestLocalStorageScope.new),
      securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
      notificationServiceProvider.overrideWithValue(FakeReminderScheduler()),
      gigaChatClientProvider.overrideWith((ref) => withKey
          ? GigaChatClient(
              authKey: _key,
              connect: () async => server.client,
            )
          : null),
    ]);
    addTearDown(container.dispose);
    await container.read(memoryItemsLoadProvider.future);
    await container.read(recurrenceLoadProvider.future);
    return container;
  }

  final jarvis =
      StateNotifierProvider<JarvisController, JarvisConversation>((ref) {
    return JarvisController(
      ref.watch(jarvisExecutorProvider),
      brain: () async => ref.read(jarvisBrainProvider),
      clock: () => now,
    );
  });

  Future<String> say(ProviderContainer container, String text) async {
    await container.read(jarvis.notifier).send(text);
    return container.read(jarvis).messages.last.text;
  }

  test('вопрос, на который правила не отвечают, уходит нейросети', () async {
    final c = await start();
    server.replies.add({
      'role': 'assistant',
      'content': 'Из-за рассеяния света, **сэр**.',
    });
    expect(await say(c, 'почему небо голубое?'), 'Из-за рассеяния света, сэр.');
    final sent = server.requests.single;
    final messages = sent['messages'] as List;
    expect((messages.first as Map)['role'], 'system');
    expect((messages.first as Map)['content'], contains('2099-10-08'));
    expect((messages.last as Map)['content'], 'почему небо голубое');
    expect((sent['functions'] as List).map((f) => (f as Map)['name']),
        contains('run_command'));
  });

  test('нейросеть действует той же рукой: run_command заводит запись', () async {
    final c = await start();
    server.replies
      ..add({
        'role': 'assistant',
        'content': '',
        'function_call': {
          'name': 'run_command',
          'arguments': {'phrase': 'завтра в 10 врач'},
        },
        'functions_state_id': 'state-1',
      })
      ..add({'role': 'assistant', 'content': 'Записал вас к врачу на завтра.'});
    expect(
        await say(c,
            'мне бы сходить к врачу наконец, запиши меня куда-нибудь на завтра'),
        'Записал вас к врачу на завтра, сэр.');
    expect(c.read(memoryItemsControllerProvider).single.body, 'Врач');
    final second = server.requests.last['messages'] as List;
    expect((second.last as Map)['role'], 'function');
    expect((second[second.length - 2] as Map)['functions_state_id'], 'state-1');
    expect(jsonDecode((second.last as Map)['content'] as String)['result'],
        contains('Записал'));

    await c.read(jarvis.notifier).undo();
    expect(c.read(memoryItemsControllerProvider), isEmpty);
  });

  test('разговор без просьбы записать уходит нейросети, а не в календарь',
      () async {
    final c = await start();
    server.replies.add({
      'role': 'assistant',
      'content': 'Да, сэр, это фильм 2023 года.',
    });
    expect(await say(c, 'ты знаешь фильм Soulmate'),
        'Да, сэр, это фильм 2023 года.');
    expect(c.read(memoryItemsControllerProvider), isEmpty);
  });

  test('ключ, испорченный текстом, — понятная причина, а не «что-то '
      'пошло не так»', () async {
    // Так однажды вышло на телефоне: в поле ключа попала фраза.
    server = _FakeGigaChat();
    final container = ProviderContainer(overrides: [
      localStorageScopeFactoryProvider
          .overrideWithValue(TestLocalStorageScope.new),
      securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
      notificationServiceProvider.overrideWithValue(FakeReminderScheduler()),
      gigaChatClientProvider.overrideWith((ref) => GigaChatClient(
            authKey: 'какой день на этой неделе у меня самый свободный',
            connect: () async => server.client,
          )),
    ]);
    addTearDown(container.dispose);
    await container.read(memoryItemsLoadProvider.future);
    final jarvisInTest = container.read(jarvis.notifier);
    await jarvisInTest.send('что такое ипотека');
    expect(container.read(jarvis).messages.last.text,
        contains('не похож на настоящий'));
    expect(server.requests, isEmpty, reason: 'с таким ключом не стучатся');
  });

  test('погода из интернета, город запоминается', () async {
    server = _FakeGigaChat();
    final hosts = <String>[];
    final online = JarvisOnline(
      fetch: OnlineFetch(
        client: MockClient((request) async {
          hosts.add(request.url.host);
          return http.Response('unavailable', 503);
        }),
      ),
    );
    final container = ProviderContainer(overrides: [
      localStorageScopeFactoryProvider
          .overrideWithValue(TestLocalStorageScope.new),
      securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
      notificationServiceProvider.overrideWithValue(FakeReminderScheduler()),
      jarvisOnlineProvider.overrideWithValue(online),
      gigaChatClientProvider.overrideWith((ref) =>
          GigaChatClient(authKey: _key, connect: () async => server.client)),
    ]);
    addTearDown(container.dispose);
    await container.read(memoryItemsLoadProvider.future);
    server.replies
      ..add({
        'role': 'assistant',
        'content': '',
        'function_call': {
          'name': 'get_weather',
          'arguments': {'date': '2099-10-08'},
        },
      })
      ..add({'role': 'assistant', 'content': 'В каком вы городе, сэр?'});
    await container.read(jarvis.notifier).send('какая погода завтра?');
    final first = jsonDecode(
        ((server.requests.last['messages'] as List).last as Map)['content']
            as String) as Map;
    expect(first['error'], contains('Город не известен'));
    expect(hosts, isEmpty, reason: 'без города в сеть не ходят');

    server.replies
      ..add({
        'role': 'assistant',
        'content': '',
        'function_call': {
          'name': 'get_weather',
          'arguments': {'place': 'Москва'},
        },
      })
      ..add({'role': 'assistant', 'content': 'Сервис погоды недоступен.'});
    await container.read(jarvis.notifier).send('в москве');
    final second = jsonDecode(
        ((server.requests.last['messages'] as List).last as Map)['content']
            as String) as Map;
    expect(second['error'], contains('ошибкой 503'),
        reason: 'отказ сети нейросеть получает словами');
    expect(hosts, contains('geocoding-api.open-meteo.com'));
  });

  test('без ключа — честно говорит, что нужна нейросеть', () async {
    final c = await start(withKey: false);
    expect(await say(c, 'что такое ипотека'), contains('GigaChat'));
  });

  test('неверный ключ — понятная причина, а не падение', () async {
    final c = await start();
    server.tokenStatus = 401;
    expect(await say(c, 'что такое ипотека'),
        contains('Ключ GigaChat не подошёл'));
  });

  test('нейросеть видит день целиком: записи, смены и выходные', () async {
    final c = await start();
    await say(c, 'запиши завтра в 10 врач');
    await c.read(shiftSchedulesControllerProvider.notifier).add(ShiftSchedule(
          id: 'yandex',
          organizationName: 'Яндекс',
          colorValue: 0xFFE53935,
          startDate: DateTime(2099, 10, 8),
          workDays: 2,
          restDays: 2,
        ));
    server.replies
      ..add({
        'role': 'assistant',
        'content': '',
        'function_call': {
          'name': 'list_days',
          'arguments': jsonEncode({'from': '2099-10-08', 'to': '2099-10-10'}),
        },
      })
      ..add({'role': 'assistant', 'content': 'Свободна суббота.'});
    await say(c, 'какой день на этой неделе самый свободный?');
    final days = jsonDecode(
        ((server.requests.last['messages'] as List).last as Map)['content']
            as String) as List;
    expect(days[0], {
      'date': '2099-10-08',
      'day': 'четверг, 8 октября',
      'shifts': ['Яндекс'],
      'holidays': [
        'День командира надводного, подводного и воздушного корабля ВМФ '
            'России',
      ],
      'records': [
        {'title': 'Врач', 'date': '2099-10-08', 'day': 'четверг, 8 октября',
            'time': '10 часов утра'},
      ],
    });
    expect(days[2], {
      'date': '2099-10-10',
      'day': 'суббота, 10 октября',
      'weekend': true,
      'shifts': 'выходной по графикам',
      'holidays': ['Всемирный день психического здоровья'],
      'records': <Object?>[],
    });
  });

  test('JarvisBrain существует только с ключом', () async {
    final c = await start(withKey: false);
    expect(c.read(jarvisBrainProvider), isNull);
    final keyed = await start();
    expect(keyed.read(jarvisBrainProvider), isA<JarvisBrain>());
  });

  test('ключ ещё читается с диска — Джарвис его дожидается', () async {
    // Сразу после запуска ключ GigaChat ещё не прочитан из защищённого
    // хранилища. Первый вопрос нельзя считать вопросом «без нейросети»:
    // на телефоне так и вышло — до первого захода в Настройки.
    server = _FakeGigaChat();
    final slowStore = _SlowKeyStore(_key);
    final container = ProviderContainer(overrides: [
      localStorageScopeFactoryProvider
          .overrideWithValue(TestLocalStorageScope.new),
      securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
      notificationServiceProvider.overrideWithValue(FakeReminderScheduler()),
      gigaChatKeyStoreProvider.overrideWithValue(slowStore),
      gigaChatClientProvider.overrideWith((ref) {
        final key = ref.watch(gigaChatKeyProvider).valueOrNull;
        return key == null
            ? null
            : GigaChatClient(authKey: key, connect: () async => server.client);
      }),
    ]);
    addTearDown(container.dispose);
    await container.read(memoryItemsLoadProvider.future);
    server.replies.add({'role': 'assistant', 'content': 'Из-за рассеяния.'});
    await container.read(jarvisControllerProvider.notifier).send(
        'почему небо голубое?');
    expect(container.read(jarvisControllerProvider).messages.last.text,
        'Из-за рассеяния, сэр.');
  });
}

/// Хранилище, которое отвечает не сразу — как защищённое на телефоне.
class _SlowKeyStore extends GigaChatKeyStore {
  _SlowKeyStore(this._key);

  final String _key;

  @override
  Future<String?> read() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return _key;
  }
}
