import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart' show JarvisPlace;
import 'package:ezhednevnik_v2/src/app/app.dart';
import 'package:ezhednevnik_v2/src/features/calculator/state/calculator_controller.dart';
import 'package:ezhednevnik_v2/src/features/jarvis/state/jarvis_brain_providers.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/memory_items.dart';
import 'package:ezhednevnik_v2/src/features/security/security.dart';
import 'package:ezhednevnik_v2/src/shared/state/notification_providers.dart';
import 'package:ezhednevnik_v2/src/features/jarvis/state/jarvis_controller.dart';
import 'package:ezhednevnik_v2/src/features/jarvis/state/jarvis_keep_awake.dart';
import 'package:ezhednevnik_v2/src/features/jarvis/state/jarvis_listener.dart';
import 'package:ezhednevnik_v2/src/features/jarvis/state/jarvis_page.dart';
import 'package:ezhednevnik_v2/src/features/jarvis/state/jarvis_voice.dart';
import 'package:ezhednevnik_v2/src/features/jarvis/ui/jarvis_badge.dart';
import 'package:ezhednevnik_v2/src/shared/state/bool_setting_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_items_test_support.dart';
import '../../support/widget_test_harness.dart';

/// Панель Джарвиса в настоящем приложении: кнопка нижней панели, разговор
/// текстом, отмена и переход на страницу. Микрофона в тестах нет — так же,
/// как в вебе: панель обязана работать и без него.
/// Ключа GigaChat нет: Джарвис отвечает правилами.
class _NoKeyStore extends GigaChatKeyStore {
  @override
  Future<String?> read() async => null;
}

/// Микрофон без звука: имя и просьбы ему подают из теста, а дальше —
/// тишина.
class _Mic implements JarvisListener {
  void Function(String text)? phrase;
  bool _waiting = false;

  @override
  bool get continuous => _waiting;

  @override
  Future<bool> startContinuous({
    required void Function(String text) onPhrase,
    void Function(String text)? onPartial,
  }) async {
    phrase = onPhrase;
    return _waiting = true;
  }

  @override
  Future<void> stopContinuous() async => _waiting = false;

  @override
  Future<String> listen({
    void Function(String text)? onPartial,
    Duration? patience,
  }) async =>
      '';

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}

  @override
  void dispose() {}
}

/// Голос без звука: в тестах синтеза речи нет.
class _SilentVoice extends JarvisVoice {
  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}
}

/// Экран телефона: запоминает, когда его просили не гаснуть.
class _Screen implements JarvisKeepAwake {
  final calls = <bool>[];

  @override
  Future<void> keepOn(bool on) async => calls.add(on);
}

void main() {
  useTestEnvironment();

  Future<ProviderContainer> openApp(WidgetTester tester,
      {Size? size, JarvisKeepAwake? screen, _Mic? mic}) async {
    await tester.binding.setSurfaceSize(size ?? const Size(400, 860));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(testProviderScope(
      overrides: [
        if (mic != null) ...[
          jarvisListenerProvider.overrideWithValue(mic),
          jarvisVoiceProvider.overrideWithValue(_SilentVoice()),
        ],
        jarvisKeepAwakeProvider.overrideWithValue(screen ?? _Screen()),
        securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
        memoryRepositoryProvider
            .overrideWithValue(const LocalMemoryRepository()),
        notificationServiceProvider.overrideWithValue(FakeReminderScheduler()),
        // Защищённого хранилища в тестах нет: ключа GigaChat — тоже.
        gigaChatKeyStoreProvider.overrideWithValue(_NoKeyStore()),
        // Здесь проверяется лист, а не вопросы карточки: дело со временем
        // записывается сразу (вопросы — в jarvis_controller_test).
        jarvisDetailedCardsProvider.overrideWith((ref) => BoolSettingController(
            storageKey: 'jarvis_detailed_cards_test', initial: false)),
      ],
      child: const EzhednevnikV2App(),
    ));
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(
        tester.element(find.byType(EzhednevnikV2App)));
  }

  Future<void> say(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const ValueKey('jarvis_input')), text);
    // Кнопка «отправить» оживает кадром позже текста.
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('jarvis_send')));
    await tester.pumpAndSettle();
  }

  testWidgets('кнопка открывает панель, дело записывается и отменяется',
      (tester) async {
    final container = await openApp(tester);
    await tester.tap(find.byKey(const ValueKey('bottom_jarvis')));
    await tester.pumpAndSettle();
    expect(find.text('Слушаю, сэр. Чем могу помочь?'), findsOneWidget);
    // Без распознавания на устройстве вместо микрофона — «отправить».
    expect(find.byKey(const ValueKey('jarvis_mic')), findsNothing);

    await say(tester, 'завтра в 10 врач');
    expect(find.textContaining('Записал, сэр: Врач'), findsOneWidget);
    expect(container.read(memoryItemsControllerProvider), hasLength(1));

    await tester.tap(find.byKey(const ValueKey('jarvis_undo_1')));
    await tester.pumpAndSettle();
    expect(container.read(memoryItemsControllerProvider), isEmpty);
    expect(find.text('Отменил, сэр.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('готовые ответы на «во сколько?»', (tester) async {
    final container = await openApp(tester);
    await tester.tap(find.byKey(const ValueKey('bottom_jarvis')));
    await tester.pumpAndSettle();
    await say(tester, 'завтра купить хлеб');
    final allDay = find.byKey(const ValueKey('jarvis_answer_весь день'));
    await tester.ensureVisible(allDay);
    await tester.pumpAndSettle();
    await tester.tap(allDay);
    await tester.pumpAndSettle();
    final bread = container.read(memoryItemsControllerProvider).single;
    expect(bread.timeMinutes, isNull);
    expect(find.byKey(const ValueKey('jarvis_answer_весь день')), findsNothing);
  });

  testWidgets('«открой финансы» закрывает панель и открывает страницу',
      (tester) async {
    await openApp(tester);
    await tester.tap(find.byKey(const ValueKey('bottom_jarvis')));
    await tester.pumpAndSettle();
    await say(tester, 'открой финансы');
    expect(find.byKey(const ValueKey('jarvis_input')), findsNothing);
    expect(find.byKey(const ValueKey('finance_currency')), findsOneWidget);
    // Лист свернулся в значок: Джарвис остался на странице, и её видно.
    expect(find.byKey(const ValueKey('jarvis_badge')), findsOneWidget);
    expect(find.byKey(const ValueKey('jarvis_badge_caption')), findsOneWidget);
    // Нажали на значок — раскрылся лист разговора.
    await tester.tap(find.byKey(const ValueKey('jarvis_badge')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('jarvis_input')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('«посчитай на калькуляторе» — Джарвис идёт к нему и жмёт клавиши',
      (tester) async {
    final container = await openApp(tester);
    await tester.tap(find.byKey(const ValueKey('bottom_jarvis')));
    await tester.pumpAndSettle();
    final pressed = <String>[];
    container.listen(calculatorLitKeyProvider, (_, key) {
      if (key != null) pressed.add(key);
    });
    await say(tester, 'посчитай на калькуляторе 200 плюс 150');
    // Клавиши видно по одной, «=» — последней.
    expect(pressed, ['C', '2', '0', '0', '+', '1', '5', '0', '=']);
    expect(container.read(calculatorControllerProvider).expression, '200+150');
    expect(container.read(calculatorLitKeyProvider), isNull);
    // Он на странице калькулятора — значком, и ответ у значка.
    expect(find.byKey(const ValueKey('jarvis_input')), findsNothing);
    expect(find.byKey(const ValueKey('jarvis_badge')), findsOneWidget);
    expect(find.textContaining('200 плюс 150 — будет 350'), findsOneWidget);
    await tester.pump(JarvisBadge.quiet);
    await tester.pumpAndSettle();
  });

  testWidgets('«посмотри на календарь» — открыть, рассказать, предложить',
      (tester) async {
    final container = await openApp(tester);
    await tester.tap(find.byKey(const ValueKey('bottom_jarvis')));
    await tester.pumpAndSettle();
    await say(tester, 'посмотри на календарь');
    expect(container.read(jarvisPageProvider)?.place, JarvisPlace.calendar);
    expect(find.byKey(const ValueKey('jarvis_badge')), findsOneWidget);
    expect(find.textContaining('Запланировать что-нибудь ещё'), findsOneWidget);
    await tester.pump(JarvisBadge.quiet);
    await tester.pumpAndSettle();
  });

  testWidgets('затихший разговор уводит значок со страницы', (tester) async {
    await openApp(tester);
    await tester.tap(find.byKey(const ValueKey('bottom_jarvis')));
    await tester.pumpAndSettle();
    await say(tester, 'открой финансы');
    expect(find.byKey(const ValueKey('jarvis_badge')), findsOneWidget);
    await tester.pump(JarvisBadge.quiet);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('jarvis_badge')), findsNothing);
  });

  testWidgets('позвали по имени — значок на странице, а не лист',
      (tester) async {
    final mic = _Mic();
    final screen = _Screen();
    await openApp(tester, mic: mic, screen: screen);
    // Ожидание имени включается со следующей сверкой обстановки.
    await tester.pump(const Duration(milliseconds: 400));
    expect(mic.phrase, isNotNull, reason: 'Джарвис ждёт имя');
    mic.phrase!('джарвис открой финансы');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('jarvis_input')), findsNothing,
        reason: 'листа нет — страницу видно');
    expect(find.byKey(const ValueKey('finance_currency')), findsOneWidget);
    expect(find.byKey(const ValueKey('jarvis_badge')), findsOneWidget);
    expect(screen.calls.first, isTrue,
        reason: 'пока Джарвис здесь, экран горит');
    await tester.pump(JarvisBadge.quiet);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('jarvis_badge')), findsNothing);
    expect(screen.calls.last, isFalse);
  });

  testWidgets('очистка разговора — с подтверждением, записи остаются',
      (tester) async {
    final container = await openApp(tester);
    await tester.tap(find.byKey(const ValueKey('bottom_jarvis')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('jarvis_clear')), findsNothing,
        reason: 'пустой разговор очищать нечего');
    await say(tester, 'завтра в 10 врач');

    await tester.tap(find.byKey(const ValueKey('jarvis_clear')));
    await tester.pumpAndSettle();
    expect(find.text('Очистить разговор? Записи в календаре останутся.'),
        findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('jarvis_clear_confirm')));
    await tester.pumpAndSettle();

    expect(find.text('Слушаю, сэр. Чем могу помочь?'), findsOneWidget);
    expect(find.textContaining('Записал'), findsNothing);
    expect(container.read(memoryItemsControllerProvider), hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('пока лист открыт, экран не гаснет', (tester) async {
    // Экран владельца гаснет через 15 с, а Джарвис ждёт нейросеть и ещё
    // 12 с — продолжения. На погасшем экране Android не даёт микрофон.
    final screen = _Screen();
    await openApp(tester, screen: screen);
    await tester.tap(find.byKey(const ValueKey('bottom_jarvis')));
    await tester.pumpAndSettle();
    expect(screen.calls, [true]);
    await tester.tap(find.byKey(const ValueKey('bottom_jarvis')));
    await tester.pumpAndSettle();
    expect(screen.calls, [true, false]);
  });

  testWidgets('кнопка панели закрывает лист, а «Джарвис» его сворачивает',
      (tester) async {
    await openApp(tester);
    final input = find.byKey(const ValueKey('jarvis_input'));
    await tester.tap(find.byKey(const ValueKey('bottom_jarvis')));
    await tester.pumpAndSettle();
    expect(input, findsOneWidget);

    // Панели живут выше листа: без закрытия лист висел над новой страницей.
    await tester.tap(find.byKey(const ValueKey('top_settings')));
    await tester.pumpAndSettle();
    expect(input, findsNothing);
    expect(find.byKey(const ValueKey('settings_gigachat')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bottom_jarvis')));
    await tester.pumpAndSettle();
    expect(input, findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('bottom_jarvis')));
    await tester.pumpAndSettle();
    expect(input, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('панель помещается на узком экране и с крупным шрифтом',
      (tester) async {
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    for (final width in [320.0, 360.0, 600.0, 840.0]) {
      for (final scale in [1.0, 1.3, 2.0]) {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        await openApp(tester, size: Size(width, 800));
        await tester.tap(find.byKey(const ValueKey('bottom_jarvis')));
        await tester.pumpAndSettle();
        await say(tester, 'завтра купить хлеб');
        expect(tester.takeException(), isNull,
            reason: '$width px, текст ×$scale');
        await tester.pumpWidget(const SizedBox());
      }
    }
  });
}
