import 'dart:convert';

import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart'
    show FinanceEntry, FinanceEntryKind, RecurrenceFrequency, ShiftSchedule;
import 'package:ezhednevnik_v2/src/app/local_storage_scope_provider.dart';
import 'package:ezhednevnik_v2/src/features/jarvis/state/jarvis_brain.dart';
import 'package:ezhednevnik_v2/src/features/jarvis/state/jarvis_brain_providers.dart';
import 'package:ezhednevnik_v2/src/features/jarvis/state/jarvis_briefings.dart';
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

import 'package:ezhednevnik_v2/src/features/jarvis/state/jarvis_facts.dart';
import 'package:ezhednevnik_v2/src/features/finance/finance.dart';
import '../../support/memory_items_test_support.dart';
import '../../support/widget_test_harness.dart';

/// Ключ настоящего вида: base64 от «идентификатор:секрет».
const _key = 'Y2xpZW50LWlkOmNsaWVudC1zZWNyZXQ=';

/// Подставной GigaChat: выдаёт токен и заготовленные ответы модели по
/// очереди, запоминая, что ему прислали. `finish_reason` заготовки уходит
/// туда, где его кладёт Сбер, — рядом с сообщением, а не внутрь него.
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
    final reply = Map<String, dynamic>.of(replies.removeAt(0));
    final finish = reply.remove('finish_reason');
    return http.Response.bytes(
      utf8.encode(jsonEncode({
        'choices': [
          {'message': reply, if (finish != null) 'finish_reason': finish},
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

  test('нейросеть действует той же рукой: run_command заводит запись',
      () async {
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

  test(
      'ключ, испорченный текстом, — понятная причина, а не «что-то '
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
    final first = jsonDecode(((server.requests.last['messages'] as List).last
        as Map)['content'] as String) as Map;
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
    final second = jsonDecode(((server.requests.last['messages'] as List).last
        as Map)['content'] as String) as Map;
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
    await say(c, 'в какие дни на этой неделе я посвободнее?');
    final days = jsonDecode(((server.requests.last['messages'] as List).last
        as Map)['content'] as String) as List;
    expect(days[0], {
      'date': '2099-10-08',
      'day': 'четверг, 8 октября',
      'shifts': ['Яндекс'],
      'holidays': [
        'День командира надводного, подводного и воздушного корабля ВМФ '
            'России',
      ],
      'records': [
        {
          // Номер — чтобы поправить именно эту запись (update_record).
          'id': c.read(memoryItemsControllerProvider).single.id,
          'title': 'Врач',
          'date': '2099-10-08',
          'day': 'четверг, 8 октября',
          'time': '10 часов утра',
          'until': '10:30 утра',
          // Напоминание — признак важного: по нему нейросеть начинает с главного.
          'reminder': true,
        },
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
    await container
        .read(jarvisControllerProvider.notifier)
        .send('почему небо голубое?');
    expect(container.read(jarvisControllerProvider).messages.last.text,
        'Из-за рассеяния, сэр.');
  });

  test('нейросеть запоминает о хозяине и видит это в следующий раз', () async {
    final c = await start();
    server.replies
      ..add({
        'role': 'assistant',
        'content': '',
        'function_call': {
          'name': 'remember_fact',
          'arguments': {'fact': 'Хозяин живёт в Казани'},
        },
        'functions_state_id': 'state-1',
      })
      ..add({'role': 'assistant', 'content': 'Запомнил, что вы в Казани.'})
      ..add({'role': 'assistant', 'content': 'В Казани.'});
    await say(c, 'кстати, я перебрался в Казань, имей это в виду');
    expect(c.read(jarvisFactsProvider), ['Хозяин живёт в Казани']);
    await say(c, 'а где я теперь живу');
    final system = (server.requests.last['messages'] as List).first as Map;
    expect(system['content'], contains('- Хозяин живёт в Казани'));
    expect(
        system['content'], contains('Никогда не называй его «пользователь»'));
  });

  test('деньги нейросеть берёт только из журнала финансов', () async {
    final c = await start();
    await c.read(financeControllerProvider.notifier).add(FinanceEntry(
          id: 'salary',
          kind: FinanceEntryKind.income,
          amount: '45000',
          currencyCode: 'RUB',
          category: 'Зарплата',
          occurredOn: DateTime(2099, 9, 5),
          createdAt: now,
          updatedAt: now,
        ));
    server.replies
      ..add({
        'role': 'assistant',
        'content': '',
        'function_call': {
          'name': 'list_finance',
          'arguments': {'from': '2099-09-01', 'to': '2099-09-30'},
        },
        'functions_state_id': 'state-1',
      })
      ..add({'role': 'assistant', 'content': 'Зарплата пришла 5 сентября.'});
    await say(c, 'слушай, а зарплата-то в прошлом месяце когда упала');
    final answer = (server.requests.last['messages'] as List).last as Map;
    final finance = jsonDecode(answer['content'] as String) as Map;
    expect((finance['entries'] as List).single['category'], 'Зарплата');
    expect((finance['totals'] as Map)['доходы RUB'], '45000.00');
  });

  Map<String, dynamic> calls(String name, Map<String, Object?> arguments) => {
        'role': 'assistant',
        'content': '',
        'function_call': {'name': name, 'arguments': arguments},
      };

  Map<Object?, Object?> lastResult() => jsonDecode(
      ((server.requests.last['messages'] as List).last as Map)['content']
          as String) as Map;

  test('наговоренное нейросеть раскладывает по полям записи, а не в название',
      () async {
    final c = await start();
    server.replies
      ..add(calls('create_record', {
        'title': 'врач',
        'date': '2099-10-08',
        'time': '10:00',
        'duration_minutes': 90,
        'address': 'улица Ленина, 5',
        'todo': 'взять полис',
        'urgent': true,
      }))
      ..add({'role': 'assistant', 'content': 'Записал врача на четверг.'});
    await say(c,
        'короче в четверг к десяти к врачу на Ленина 5, там часа полтора, полис не забыть, это срочно');
    final item = c.read(memoryItemsControllerProvider).single;
    expect(item.title, 'Врач');
    expect(item.memoryDate, DateTime(2099, 10, 8));
    expect((item.timeMinutes, item.endMinutes), (600, 690));
    expect(item.priority, 1);
    expect(item.body, allOf(contains('Ленина, 5'), contains('взять полис')));
    expect(item.body, isNot(contains('Врач')),
        reason: 'название и длительность — у самой записи');

    await c.read(jarvis.notifier).undo();
    expect(c.read(memoryItemsControllerProvider), isEmpty);
  });

  test('нейросеть правит запись одной правкой — и одной отменой', () async {
    final c = await start();
    await say(c, 'запиши завтра в 10 врач');
    server.replies
      ..add(calls('update_record', {
        'query': 'врач',
        'time': '12:00',
        'add_text': 'взять полис',
        'remind_minutes_before': 60,
      }))
      ..add({'role': 'assistant', 'content': 'Перенёс врача на полдень.'});
    await say(c, 'врача сдвинь на полдень, напомни за час и полис допиши');
    final moved = c.read(memoryItemsControllerProvider).single;
    expect(moved.timeMinutes, 720);
    expect(moved.remindAt, DateTime(2099, 10, 8, 11));
    expect(moved.body, contains('взять полис'));
    expect(lastResult()['result'], startsWith('Поправил.'));

    await c.read(jarvis.notifier).undo();
    final back = c.read(memoryItemsControllerProvider).single;
    expect(back.timeMinutes, 600);
    expect(back.body, isNot(contains('взять полис')));
  });

  test('подходят несколько записей — нейросеть выбирает, а не правит наугад',
      () async {
    final c = await start();
    await say(c, 'запиши завтра в 10 врач');
    await say(c, 'запиши послезавтра в 9 врач');
    server.replies
      ..add(calls('update_record', {'query': 'врач', 'time': '12:00'}))
      ..add({'role': 'assistant', 'content': 'Какого из врачей, сэр?'});
    await say(c, 'врача сдвинь на полдень');
    expect(lastResult()['choose'], hasLength(2));
    expect(
        c.read(memoryItemsControllerProvider).map((item) => item.timeMinutes),
        unorderedEquals([600, 540]));
  });

  test('повтор у готовой записи — серией, как в редакторе, и с отменой',
      () async {
    final c = await start();
    await say(c, 'запиши завтра в 10 врач');
    final id = c.read(memoryItemsControllerProvider).single.id;
    server.replies
      ..add(calls('update_record', {'id': id, 'repeat': 'monthly'}))
      ..add({'role': 'assistant', 'content': 'Теперь каждый месяц.'})
      ..add(calls('update_record', {'query': 'врач', 'repeat': 'none'}))
      ..add({'role': 'assistant', 'content': 'Больше не повторяю.'});

    // «Пусть врач будет каждый месяц» правила понимают сами — нейросети
    // достаётся то, что сказано по-своему.
    await say(c, 'а врача можно сделать постоянным, раз в месяц чтоб был');
    expect(lastResult()['result'], 'Врач — каждый месяц 8-го в 10 часов утра.');
    expect(c.read(recurrenceSeriesControllerProvider).single.frequency,
        RecurrenceFrequency.monthly);

    await say(c, 'врача больше не повторяй');
    expect(lastResult()['result'], '«Врач» больше не повторяется.');
    expect(c.read(recurrenceSeriesControllerProvider), isEmpty);
    expect(c.read(memoryItemsControllerProvider).single.id, id,
        reason: 'запись снова живёт строкой со своим номером');

    await c.read(jarvis.notifier).undo();
    expect(c.read(recurrenceSeriesControllerProvider).single.frequency,
        RecurrenceFrequency.monthly);
  });

  test('настройки нейросеть видит и меняет — с отменой', () async {
    final c = await start();
    server.replies
      ..add(calls('get_settings', {}))
      ..add(calls(
          'change_setting', {'setting': 'speakReminders', 'enabled': false}))
      ..add(calls(
          'change_setting', {'setting': 'morningBriefing', 'time': '07:30'}))
      ..add({'role': 'assistant', 'content': 'Готово, сэр.'});
    await say(c,
        'напоминания вслух не читай, а утром присылай сводку пораньше, к половине восьмого');
    final requests = server.requests;
    final seen = jsonDecode(((requests[1]['messages'] as List).last
        as Map)['content'] as String) as Map;
    expect((seen['speakReminders'], seen['morningBriefing']), (true, 'в 9:00'));
    expect(c.read(jarvisSpeakRemindersProvider), isFalse);
    expect(c.read(jarvisBriefingSettingsProvider).morningAt, 7 * 60 + 30);

    await c.read(jarvis.notifier).undo();
    expect(c.read(jarvisSpeakRemindersProvider), isTrue);
    expect(c.read(jarvisBriefingSettingsProvider).morningAt, 9 * 60);
  });

  test('будильник у записи — звук будильника телефона', () async {
    final c = await start();
    await say(c, 'запиши завтра в 10 врач');
    server.replies
      ..add(calls('update_record', {'query': 'врач', 'alarm': true}))
      ..add({'role': 'assistant', 'content': 'Разбужу.'});
    await say(c, 'к врачу меня разбуди будильником, а не пиликалкой');
    final item = c.read(memoryItemsControllerProvider).single;
    expect((item.reminderSoundUri, item.reminderSoundName),
        ('content://alarm/default', defaultAlarmSoundName));
  });

  test('две просьбы в одной фразе — нейросети, а не половина правилам',
      () async {
    final c = await start();
    await say(c, 'запиши завтра в 10 врач');
    final id = c.read(memoryItemsControllerProvider).single.id;
    server.replies
      ..add(calls('update_record',
          {'id': id, 'date': '2099-10-09', 'remind_minutes_before': 60}))
      ..add({'role': 'assistant', 'content': 'Перенёс и напомню за час.'});
    await say(c, 'перенеси врача на пятницу и напомни за час');
    final doctor = c.read(memoryItemsControllerProvider).single;
    expect((doctor.memoryDate, doctor.remindAt),
        (DateTime(2099, 10, 9), DateTime(2099, 10, 9, 9)));
  });

  test('трату нейросеть пишет в журнал финансов со статьёй', () async {
    final c = await start();
    server.replies
      ..add(calls('add_finance',
          {'kind': 'expense', 'amount': 1000, 'category': 'продукты'}))
      ..add({'role': 'assistant', 'content': 'Записал тысячу на продукты.'});
    // Правила «косаря» не знают — понимает нейросеть.
    await say(c, 'в пятёрочке косарь оставил на продукты');
    final entry = c.read(financeControllerProvider).single;
    expect((entry.kind, entry.amount, entry.category, entry.occurredOn),
        (FinanceEntryKind.expense, '1000', 'Продукты', DateTime(2099, 10, 7)));

    await c.read(jarvis.notifier).undo();
    expect(c.read(financeControllerProvider), isEmpty);
  });

  test('исчерпав обращения к данным, нейросеть всё равно отвечает словами',
      () async {
    // Полгода инструкция велит смотреть по шесть недель — это уже пять
    // обращений. Шестое съедало ответ: текста у нейросети больше не
    // просили, и Джарвис молчал.
    final c = await start();
    for (var call = 0; call < 6; call++) {
      server.replies.add({
        'role': 'assistant',
        'content': '',
        'function_call': {
          'name': 'list_days',
          'arguments': {'from': '2099-04-01', 'to': '2099-05-12'},
        },
        'functions_state_id': 'state-$call',
      });
    }
    server.replies
        .add({'role': 'assistant', 'content': 'За полгода всё сделано, сэр.'});
    expect(
        await say(c, 'почему небо голубое?'), 'За полгода всё сделано, сэр.');
    expect([for (final request in server.requests) request['function_call']],
        [...List.filled(6, 'auto'), 'none']);
  });

  test('ответ, оборванный лимитом токенов, не читается на полуслове', () async {
    final c = await start();
    server.replies.add({
      'role': 'assistant',
      'content': 'Сэр, новостей сегодня много. Главная из них — то, что',
      'finish_reason': 'length',
    });
    expect(
        await say(c, 'почему небо голубое?'), 'Сэр, новостей сегодня много.');
  });
}

class _SlowKeyStore extends GigaChatKeyStore {
  _SlowKeyStore(this._key);

  final String _key;

  @override
  Future<String?> read() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return _key;
  }
}
