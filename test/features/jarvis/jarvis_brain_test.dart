import 'dart:convert';

import 'package:ez_data/ez_data.dart';
import 'package:ezhednevnik_v2/src/app/local_storage_scope_provider.dart';
import 'package:ezhednevnik_v2/src/features/jarvis/state/jarvis_brain.dart';
import 'package:ezhednevnik_v2/src/features/jarvis/state/jarvis_brain_providers.dart';
import 'package:ezhednevnik_v2/src/features/jarvis/state/jarvis_controller.dart';
import 'package:ezhednevnik_v2/src/features/jarvis/state/jarvis_message.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/memory_items.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/recurrence.dart';
import 'package:ezhednevnik_v2/src/features/security/security.dart';
import 'package:ezhednevnik_v2/src/shared/state/notification_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/memory_items_test_support.dart';
import '../../support/widget_test_harness.dart';

/// Подставной GigaChat: выдаёт токен и заготовленные ответы модели по
/// очереди, запоминая, что ему прислали.
class _FakeGigaChat {
  final replies = <Map<String, dynamic>>[];
  final requests = <Map<String, dynamic>>[];
  int tokenStatus = 200;

  late final client = MockClient((request) async {
    if (request.url.path.endsWith('/oauth')) {
      expect(request.headers['Authorization'], 'Basic КЛЮЧ');
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
              authKey: 'КЛЮЧ',
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
      brain: () => ref.read(jarvisBrainProvider),
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

  test('записи за дни видны нейросети', () async {
    final c = await start();
    await say(c, 'завтра в 10 врач');
    server.replies
      ..add({
        'role': 'assistant',
        'content': '',
        'function_call': {
          'name': 'list_records',
          'arguments': jsonEncode({'from': '2099-10-08', 'to': '2099-10-08'}),
        },
      })
      ..add({'role': 'assistant', 'content': 'Завтра врач в десять.'});
    await say(c, 'что мне важнее всего завтра?');
    final result = jsonDecode(
        ((server.requests.last['messages'] as List).last as Map)['content']
            as String) as List;
    expect(result.single, {
      'title': 'Врач',
      'date': '2099-10-08',
      'time': '10 часов утра',
    });
  });

  test('JarvisBrain существует только с ключом', () async {
    final c = await start(withKey: false);
    expect(c.read(jarvisBrainProvider), isNull);
    final keyed = await start();
    expect(keyed.read(jarvisBrainProvider), isA<JarvisBrain>());
  });
}
