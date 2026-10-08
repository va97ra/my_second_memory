import 'package:ez_data/ez_data.dart';
import 'package:ezhednevnik_v2/src/app/app.dart';
import 'package:ezhednevnik_v2/src/features/jarvis/state/jarvis_listener.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/memory_items.dart';
import 'package:ezhednevnik_v2/src/features/security/security.dart';
import 'package:ezhednevnik_v2/src/shared/state/notification_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_items_test_support.dart';
import '../../support/widget_test_harness.dart';

/// Панель Джарвиса в настоящем приложении: кнопка нижней панели, разговор
/// текстом, отмена и переход на страницу. Микрофона в тестах нет — так же,
/// как в вебе: панель обязана работать и без него.
void main() {
  useTestEnvironment();

  Future<ProviderContainer> openApp(WidgetTester tester, {Size? size}) async {
    await tester.binding.setSurfaceSize(size ?? const Size(400, 860));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(testProviderScope(
      overrides: [
        securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
        memoryRepositoryProvider.overrideWithValue(const LocalMemoryRepository()),
        notificationServiceProvider.overrideWithValue(FakeReminderScheduler()),
        jarvisListenerProvider.overrideWithValue(null),
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
