import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/app/local_storage_scope_provider.dart';
import 'package:ezhednevnik_v2/src/app/theme/app_theme_controller.dart';
import 'package:ezhednevnik_v2/src/features/calculator/state/calculator_controller.dart';
import 'package:ezhednevnik_v2/src/features/jarvis/state/jarvis_controller.dart';
import 'package:ezhednevnik_v2/src/features/jarvis/state/jarvis_executor.dart';
import 'package:ezhednevnik_v2/src/features/jarvis/state/jarvis_facts.dart';
import 'package:ezhednevnik_v2/src/features/jarvis/state/jarvis_message.dart';
import 'package:ezhednevnik_v2/src/features/jarvis/state/jarvis_page.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/memory_items.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/recurrence.dart';
import 'package:ezhednevnik_v2/src/features/security/security.dart';
import 'package:ezhednevnik_v2/src/shared/state/notification_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_items_test_support.dart';
import '../../support/widget_test_harness.dart';

/// Разговор с Джарвисом на настоящих контроллерах записей, повторов и темы:
/// фраза доходит до хранилища тем же путём, что и правка с экрана.
void main() {
  useTestEnvironment();
  // Среда, 7 октября 2099, 14:00 — далеко впереди, чтобы напоминания были в
  // будущем при любом настоящем времени.
  final now = DateTime(2099, 10, 7, 14);
  final jarvis =
      StateNotifierProvider<JarvisController, JarvisConversation>((ref) {
    return JarvisController(
      JarvisExecutor(ref, address: jarvisAddress),
      clock: () => now,
    );
  });

  /// Контейнер с дочитанными записями и повторами: иначе тест кончается
  /// раньше загрузки, и она дописывает уже закрытые контроллеры.
  Future<ProviderContainer> start() async {
    final container = ProviderContainer(overrides: [
      localStorageScopeFactoryProvider
          .overrideWithValue(TestLocalStorageScope.new),
      securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
      notificationServiceProvider.overrideWithValue(FakeReminderScheduler()),
      // Как в main.dart: тема читается до запуска, а не вдогонку.
      appThemeControllerProvider
          .overrideWith((ref) => AppThemeController(loadOnStart: false)),
    ]);
    addTearDown(container.dispose);
    await container.read(memoryItemsLoadProvider.future);
    await container.read(recurrenceLoadProvider.future);
    return container;
  }

  Future<String> say(ProviderContainer container, String text) async {
    await container.read(jarvis.notifier).send(text);
    return container.read(jarvis).messages.last.text;
  }

  List<MemoryItem> rows(ProviderContainer container) =>
      container.read(memoryItemsControllerProvider);

  test('дело с днём и временем записывается с напоминанием и отменяется',
      () async {
    final c = await start();
    expect(await say(c, 'Джарвис, завтра в 10 врач'),
        'Записал, сэр: Врач — завтра в 10 часов утра.');
    final doctor = rows(c).single;
    expect(doctor.body, 'Врач');
    expect(doctor.memoryDate, DateTime(2099, 10, 8));
    expect(doctor.timeMinutes, 600);
    expect(doctor.remindAt, DateTime(2099, 10, 8, 10));
    expect(doctor.transcript, 'Джарвис, завтра в 10 врач');
    expect(c.read(jarvis).undoMessageId, c.read(jarvis).messages.last.id);

    expect(await say(c, 'что у меня завтра'),
        'Сэр, на завтра одно дело: в 10 часов утра — врач.');

    await c.read(jarvis.notifier).undo();
    expect(rows(c), isEmpty);
    expect(c.read(jarvis).messages.last.text, 'Отменил, сэр.');
    expect(c.read(jarvis).undoMessageId, isNull);
  });

  test('без дня и времени — спрашивает по очереди', () async {
    final c = await start();
    expect(await say(c, 'запиши купить молоко'),
        'На какой день вам назначить «Купить молоко», сэр?');
    expect(c.read(jarvis).asking?.title, 'Купить молоко');
    expect(await say(c, 'послезавтра'),
        'На какое время вам назначить «Купить молоко», сэр?');
    expect(await say(c, 'весь день'),
        'Записал, сэр: Купить молоко — послезавтра, весь день.');
    expect(rows(c).single.timeMinutes, isNull);
    expect(c.read(jarvis).asking, isNull);
  });

  test('«не надо» на вопрос — ничего не записывает', () async {
    final c = await start();
    await say(c, 'запиши купить молоко');
    expect(
        await say(c, 'не надо'), 'Хорошо, «Купить молоко» не записываю, сэр.');
    expect(rows(c), isEmpty);
  });

  test('новая просьба вместо ответа: начатое — запиской, просьба — исполнена',
      () async {
    final c = await start();
    await say(c, 'запиши купить молоко');
    expect(await say(c, 'открой календарь'), 'Открываю календарь, сэр.');
    expect(rows(c).single.isUndated, isTrue);
    expect(c.read(jarvis).navigation?.target.place, JarvisPlace.calendar);
    c.read(jarvis.notifier).navigationHandled();
    expect(c.read(jarvis).navigation, isNull);
  });

  test('«перенеси его» — про только что записанное, напоминание едет следом',
      () async {
    final c = await start();
    await say(c, 'завтра в 10 врач');
    expect(await say(c, 'перенеси его на 12 октября в 12'),
        'Перенёс «Врач» — теперь в понедельник в полдень, сэр.');
    final moved = rows(c).single;
    expect(moved.memoryDate, DateTime(2099, 10, 12));
    expect(moved.timeMinutes, 12 * 60);
    expect(moved.remindAt, DateTime(2099, 10, 12, 12));

    await say(c, 'отмени');
    expect(rows(c).single.memoryDate, DateTime(2099, 10, 8));
  });

  test('отметить по словам и вернуть в работу', () async {
    final c = await start();
    await say(c, 'завтра в 10 сходить к стоматологу');
    expect(await say(c, 'отметь стоматолога сделанным'),
        'Отметил, сэр: «Сходить к стоматологу» выполнено.');
    expect(rows(c).single.isDone, isTrue);
    await say(c, 'отмени');
    expect(rows(c).single.isDone, isFalse);
    expect(await say(c, 'отметь бассейн сделанным'),
        startsWith('Не нашёл записи про «бассейн»'));
  });

  test('ежемесячный повтор заводит серию, отмена её удаляет', () async {
    final c = await start();
    expect(await say(c, 'каждый месяц 10-го платить за квартиру'),
        'На какое время вам назначить «Платить за квартиру», сэр?');
    expect(
        await say(c, 'в 9 утра'),
        'Записал, сэр: Платить за квартиру — каждый месяц 10-го в 9 часов '
        'утра.');
    expect(c.read(recurrenceSeriesControllerProvider), hasLength(1));
    await say(c, 'отмени');
    expect(c.read(recurrenceSeriesControllerProvider), isEmpty);
  });

  test('тема и отмена', () async {
    final c = await start();
    final before = c.read(appThemeControllerProvider);
    expect(await say(c, 'включи тёмную тему'), 'Включил тёмную тему, сэр.');
    expect(c.read(appThemeControllerProvider), AppThemeStyle.notebookDark);
    await say(c, 'отмени');
    expect(c.read(appThemeControllerProvider), before);
  });

  test('без просьбы и без дня не записывает, а спрашивает', () async {
    final c = await start();
    expect(await say(c, 'ты знаешь фильм Soulmate'),
        startsWith('Что вы хотите, сэр? Чтобы записать'));
    expect(rows(c), isEmpty);
    // С днём — диктовка дела, её записывают и без «запиши».
    expect(await say(c, 'завтра в 10 врач'), startsWith('Записал'));
  });

  test('отменять нечего', () async {
    final c = await start();
    expect(
        await say(c, 'отмени'), 'Отменять нечего, сэр: я ещё ничего не менял.');
  });

  test('«запомни»: без нейросети отвечает из запомненного, «Отменить» стирает',
      () async {
    final c = await start();
    expect(await say(c, 'Джарвис, запомни, что я живу в Казани'),
        'Запомнил, сэр: я живу в Казани.');
    expect(c.read(jarvisFactsProvider), ['Я живу в Казани']);
    expect(await say(c, 'где я живу?'), 'Вы говорили, сэр: я живу в Казани.');
    await c.read(jarvis.notifier).undo();
    expect(c.read(jarvisFactsProvider), isEmpty);
  });

  test('прошлое: что сделано и что не отмечено; важное — первым', () async {
    final c = await start();
    final items = c.read(memoryItemsControllerProvider.notifier);
    MemoryItem row(String title, DateTime day,
            {int? minutes, MemoryStatus status = MemoryStatus.active}) =>
        MemoryItem(
          id: 'row_$title',
          type: MemoryType.task,
          title: title,
          memoryDate: day,
          timeMinutes: minutes,
          status: status,
          createdAt: now,
          updatedAt: now,
        );
    final yesterday = DateTime(2099, 10, 6);
    await items
        .add(row('Врач', yesterday, minutes: 600, status: MemoryStatus.done));
    await items.add(row('Купить хлеб', yesterday));
    expect(await say(c, 'что я делал вчера'),
        'Вчера, сэр: в 10 часов утра — врач, сделано; купить хлеб.');
    expect(await say(c, 'что я не закончил вчера'),
        'Вчера не отмечено одно дело, сэр: купить хлеб.');

    await say(c, 'завтра в 10 оплатить интернет');
    await say(c, 'запиши завтра купить молоко');
    expect(
        await say(c, 'что самое важное завтра'),
        'Сэр, самое важное на завтра: в 10 часов утра — оплатить интернет. '
        'Остальное: купить молоко.');
  });

  test('подробная карточка: вопрос за вопросом, запись с таблицей', () async {
    final c = await start();
    final detailed =
        StateNotifierProvider<JarvisController, JarvisConversation>((ref) {
      return JarvisController(
        JarvisExecutor(ref, address: jarvisAddress),
        detailed: () => true,
        clock: () => now,
      );
    });
    Future<String> ask(String text) async {
      await c.read(detailed.notifier).send(text);
      return c.read(detailed).messages.last.text;
    }

    expect(await ask('запиши на завтра на 12 часов дня врач'),
        startsWith('Сколько займёт «Врач»'));
    expect(c.read(detailed).askingNeed, TaskNeed.duration);
    expect(await ask('полчаса'), startsWith('Куда нужно ехать'));
    expect(await ask('на Ленина 5'), startsWith('Что там сделать'));
    expect(await ask('взять паспорт'), startsWith('Это срочно'));
    expect(
        await ask('да'),
        'Записал, сэр: Врач — завтра в полдень, на 30 минут, Ленина, 5, '
        'срочно. Скажите «как доехать» — проложу маршрут.');
    final doctor = rows(c).single;
    expect(doctor.timeMinutes, 12 * 60);
    expect(doctor.endMinutes, 12 * 60 + 30);
    expect(doctor.priority, 1);
    expect(
        doctor.body,
        'Что: Врач\nСколько: 30 минут\nКуда: Ленина, 5\n'
        'Что сделать: Взять паспорт\nСрочность: срочно');
    expect(c.read(detailed).askingNeed, isNull);
  });

  test('подробная карточка: «не важно» пропускает вопрос', () async {
    final c = await start();
    final detailed =
        StateNotifierProvider<JarvisController, JarvisConversation>((ref) {
      return JarvisController(
        JarvisExecutor(ref, address: jarvisAddress),
        detailed: () => true,
        clock: () => now,
      );
    });
    Future<void> ask(String text) => c.read(detailed.notifier).send(text);
    await ask('запиши завтра в 10 зарядка');
    for (final answer in ['не важно', 'никуда', 'ничего', 'нет']) {
      await ask(answer);
    }
    final row = rows(c).single;
    expect(row.body, 'Зарядка');
    expect(row.endMinutes, 10 * 60 + 30,
        reason:
            'длительность не назвали — табличка в полчаса, а не в четверть');
    expect(row.priority, 0);
  });

  test('калькулятор: Джарвис нажимает клавиши и читает ответ', () async {
    final c = await start();
    String shown() => c.read(calculatorControllerProvider).expression;

    expect(await say(c, 'сколько будет 25 на 4'), contains('будет 100'));
    expect(shown(), '25×4', reason: 'посчитанное голосом — на калькуляторе');
    expect(await say(c, 'а теперь прибавь 10'), contains('Получается 110'));
    expect(shown(), '25×4+10');
    expect(await say(c, 'умножь на 2'), contains('Получается 220'));
    expect(shown(), '(25×4+10)×2', reason: 'умножают результат');
    expect(await say(c, 'сохрани в память'), contains('220'));
    expect(c.read(calculatorControllerProvider).memory, '220');
    expect(await say(c, 'очисти калькулятор'), contains('очищен'));
    expect(shown(), isEmpty);
    expect(await say(c, 'что в памяти'), contains('В памяти'));
    await say(c, 'отмени');
    expect(shown(), '(25×4+10)×2', reason: 'отмена возвращает калькулятор');
    await say(c, 'сбрось');
    expect(await say(c, 'прибавь 5'), contains('Калькулятор пуст'));
  });

  test('посмотри: о странице на экране и о названной', () async {
    final c = await start();
    await say(c, 'запиши завтра в 10 врач');
    final page = c.read(jarvisPageProvider.notifier);

    page.state = const OpenPlace(JarvisPlace.calendar);
    final told = await say(c, 'что здесь');
    expect(told, contains('рач'), reason: 'дела ближайшей недели');
    expect(told, endsWith(JarvisReplies.planMore));
    expect(c.read(jarvis).navigation?.target.place, JarvisPlace.calendar,
        reason: 'страницу видно: лист сворачивается в значок');
    expect(await say(c, 'да'), startsWith('Что записать'));

    page.state = const OpenPlace(JarvisPlace.accounts);
    expect(await say(c, 'прочитай'), contains('не читаю'));

    expect(
        await say(c, 'посмотри на калькулятор'), contains('Калькулятор пуст'));
    expect(c.read(jarvis).navigation?.target.place, JarvisPlace.calculator,
        reason: 'названная страница — Джарвис идёт на неё');
  });
}
