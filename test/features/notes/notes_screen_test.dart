import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/app/app.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ezhednevnik_v2/src/features/security/security.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/widget_test_harness.dart';

void main() {
  useTestEnvironment();

  MemoryItem note(String id, String body) {
    final now = DateTime.now();
    return MemoryItem(
      id: id,
      type: MemoryType.note,
      title: body,
      body: body,
      memoryDate: now,
      isUndated: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<EmptyMemoryRepository> open(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = EmptyMemoryRepository()
      ..savedItems = [
        for (var i = 1; i <= 7; i++) note('n$i', 'Записка номер $i'),
      ];
    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          memoryRepositoryProvider.overrideWithValue(repository),
          securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
        ],
        child: const EzhednevnikV2App(),
      ),
    );
    await tester.pumpAndSettle();
    await openTab(tester, 'notes');
    return repository;
  }

  Finder card(String id) => find.byKey(ValueKey('memory_sticker_$id'));

  for (final (width, columns) in [
    (320.0, 3),
    (360.0, 3),
    (600.0, 3),
    (840.0, 4),
  ]) {
    testWidgets('квадратные карточки по $columns в ряд на ширине $width',
        (tester) async {
      await open(tester, Size(width, 800));

      final rects = [
        for (var i = 1; i <= 7; i++) tester.getRect(card('n$i')),
      ];
      for (final rect in rects) {
        expect(rect.width, closeTo(rect.height, 0.5));
      }
      expect({for (final rect in rects) rect.left.round()}, hasLength(columns));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('длинный текст при шрифте 2.0 не вылезает из карточки',
      (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await open(tester, const Size(320, 800));

    expect(tester.takeException(), isNull);
    expect(card('n1'), findsOneWidget);
  });

  testWidgets('полоса вида сверху, край карточки ровный', (tester) async {
    await open(tester, const Size(360, 800));

    final cardRect = tester.getRect(card('n1'));
    final strip = tester.getRect(find.byKey(const ValueKey('memory_sticker_strip_n1')));
    expect(strip.top, closeTo(cardRect.top, 1));
    expect(strip.width, closeTo(cardRect.width, 2));
    expect(
      find.descendant(
        of: card('n1'),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Material && widget.shape is TornPaperShapeBorder,
        ),
      ),
      findsNothing,
    );
  });

  testWidgets('полоса подписывает вид и дату, квадратик отмечает выполненной',
      (tester) async {
    await open(tester, const Size(360, 800));

    final strip = find.byKey(const ValueKey('memory_sticker_strip_n1'));
    final label = find.descendant(of: strip, matching: find.byType(Text));
    expect(tester.widget<Text>(label.first).data, startsWith('Записка '));
    expect(find.descendant(of: strip, matching: find.text('Выполнено')),
        findsNothing);

    await tester.tap(find.byKey(const ValueKey('memory_sticker_done_n1')));
    await tester.pumpAndSettle();
    expect(find.descendant(of: strip, matching: find.text('Выполнено')),
        findsOneWidget);
    // Нажатие на квадратик не открывает редактор.
    expect(find.byKey(const ValueKey('record_editor_text')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('memory_sticker_done_n1')));
    await tester.pumpAndSettle();
    expect(find.descendant(of: strip, matching: find.text('Выполнено')),
        findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('выполненная записка уходит вниз, под полосу', (tester) async {
    await open(tester, const Size(360, 800));
    expect(find.byKey(const ValueKey('notes_done_divider')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('memory_sticker_done_n1')));
    await tester.pumpAndSettle();

    final divider = tester.getRect(
      find.byKey(const ValueKey('notes_done_divider')),
    );
    expect(
      tester.getRect(card('n1')).top,
      greaterThanOrEqualTo(divider.bottom),
    );
    expect(tester.getRect(card('n2')).bottom, lessThan(divider.top));
    expect(find.text('Выполненные'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('карточка открывает редактор той же записи', (tester) async {
    await open(tester, const Size(360, 800));

    await tester.tap(card('n2'));
    await tester.pumpAndSettle();

    final field = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const ValueKey('record_editor_text')),
        matching: find.byType(EditableText),
      ),
    );
    expect(field.controller.text, 'Записка номер 2');
    expect(find.byKey(const ValueKey('bottom_notes')), findsOneWidget);
  });

  testWidgets('плюс заводит новую записку, и она появляется в окне',
      (tester) async {
    final repository = await open(tester, const Size(360, 800));

    await tester.tap(find.byKey(const ValueKey('notes_add')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('record_editor_text')),
      'Новая мысль',
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(
      repository.savedItems.where((item) => item.isUndated),
      hasLength(8),
    );
    await openTab(tester, 'notes');
    expect(find.text('Новая мысль'), findsOneWidget);
  });

  testWidgets('шапка та же: поиск сужает карточки, записка с датой не находится',
      (tester) async {
    await open(tester, const Size(360, 800));

    await tester.tap(find.byKey(const ValueKey('feed_search')));
    await tester.pumpAndSettle();
    expect(find.text('Поиск по запискам'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('feed_search_field')),
      'номер 3',
    );
    await tester.pumpAndSettle();

    expect(card('n3'), findsOneWidget);
    expect(card('n1'), findsNothing);
    expect(find.byKey(const ValueKey('feed_today')), findsNothing);
    expect(find.byKey(const ValueKey('feed_filter')), findsOneWidget);
  });

  testWidgets('долгое нажатие убирает записку в архив', (tester) async {
    await open(tester, const Size(360, 800));

    await tester.longPress(card('n1'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sticker_archive_n1')));
    await tester.pumpAndSettle();

    expect(card('n1'), findsNothing);
    expect(card('n2'), findsOneWidget);
  });

  testWidgets('в фильтре только виды, которые есть среди записок',
      (tester) async {
    await open(tester, const Size(360, 800));

    await tester.tap(find.byKey(const ValueKey('feed_filter')));
    await tester.pumpAndSettle();

    expect(find.text('Все записи'), findsOneWidget);
    expect(find.text('Выполненные'), findsOneWidget);
    expect(find.text('Заметка'), findsOneWidget);
    expect(find.text('День рождения'), findsNothing);
    expect(find.text('Платёж'), findsNothing);
    expect(find.text('Каждый год'), findsNothing);
  });

  testWidgets('в ленте записок нет', (tester) async {
    await open(tester, const Size(360, 800));

    await openTab(tester, 'feed');
    expect(find.text('Записка номер 1'), findsNothing);
    expect(find.byKey(const ValueKey('feed_section_notes')), findsNothing);
  });
}
