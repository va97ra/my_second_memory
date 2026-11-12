import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/app/app.dart';
import 'package:ezhednevnik_v2/src/features/home_feed/state/feed_layout_provider.dart';
import 'package:ezhednevnik_v2/src/features/home_feed/ui/widgets/feed_day_rail_bubble.dart';
import 'package:ezhednevnik_v2/src/features/home_feed/ui/widgets/feed_day_scale.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ezhednevnik_v2/src/features/security/security.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import '../../support/widget_test_harness.dart';

void main() {
  useTestEnvironment();

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final other = today.subtract(const Duration(days: 30));

  MemoryItem item(String id, DateTime day, {int? time}) => MemoryItem(
        id: id,
        type: MemoryType.task,
        title: id,
        body: id,
        memoryDate: day,
        timeMinutes: time,
        createdAt: today,
        updatedAt: today,
      );

  Future<ProviderContainer> open(
    WidgetTester tester,
    List<MemoryItem> items,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(testProviderScope(overrides: [
      memoryRepositoryProvider
          .overrideWithValue(EmptyMemoryRepository()..savedItems = items),
      securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
    ], child: const EzhednevnikV2App()));
    await tester.pumpAndSettle();
    await openTab(tester, 'feed');
    return ProviderScope.containerOf(
      tester.element(find.byKey(const ValueKey('feed_filter'))),
    );
  }

  Finder sticker(String id) => find.byKey(ValueKey('memory_sticker_$id'));

  Future<void> showAllDates(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('feed_filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Все записи').last);
    await tester.pumpAndSettle();
  }

  Future<void> carry(WidgetTester tester, Finder from, Offset to) async {
    final gesture = await tester.startGesture(tester.getCenter(from));
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.moveTo(to);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('квадратик отмечает выполненной, и листок уходит под полосу',
      (tester) async {
    final c = await open(tester, [item('a', today), item('b', today)]);

    await tester.tap(find.byKey(const ValueKey('memory_sticker_done_a')));
    await tester.pumpAndSettle();

    final layout = c.read(feedLayoutProvider);
    expect(layout.groups.expand((group) => group.itemIds), ['b']);
    expect(layout.doneItemIds, ['a']);
    expect(find.text('Выполненные'), findsOneWidget);
    expect(find.byKey(const ValueKey('record_editor_text')), findsNothing);
  });

  testWidgets('нажатие открывает редактор', (tester) async {
    await open(tester, [item('a', today)]);

    await tester.tap(sticker('a'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('record_editor_text')), findsOneWidget);
  });

  testWidgets('долгое нажатие без движения открывает меню, удаление спрашивает',
      (tester) async {
    final c = await open(tester, [item('a', today), item('b', today)]);

    await tester.longPress(sticker('a'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('sticker_move_a')), findsOneWidget);
    expect(find.byKey(const ValueKey('sticker_archive_a')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('sticker_delete_a')));
    await tester.pumpAndSettle();
    expect(c.read(feedLayoutProvider).itemIds, contains('a'));

    await tester.tap(find.widgetWithText(FilledButton, 'Удалить'));
    await tester.pumpAndSettle();
    expect(c.read(feedLayoutProvider).itemIds, ['b']);
  });

  testWidgets('листок несут на подпись другого дня, и запись туда переезжает',
      (tester) async {
    final c = await open(tester, [item('a', today), item('old', other)]);
    await showAllDates(tester);

    final oldLabel = find.ancestor(
      of: sticker('old'),
      matching: find.byType(CustomScrollView),
    );
    expect(oldLabel, findsOneWidget);
    await carry(tester, sticker('a'), tester.getCenter(sticker('old')));

    final moved = c
        .read(memoryItemsControllerProvider)
        .firstWhere((record) => record.id == 'a');
    expect(moved.memoryDate, other);
    expect(tester.takeException(), isNull);
  });

  testWidgets('внутри дня листок встаёт перед другим, со временем — нет',
      (tester) async {
    final c = await open(tester, [
      item('a', today),
      item('b', today),
      item('timed', today, time: 600),
    ]);
    expect(c.read(feedLayoutProvider).itemIds, ['timed', 'a', 'b']);

    await carry(tester, sticker('b'), tester.getCenter(sticker('a')));
    expect(c.read(feedLayoutProvider).itemIds, ['timed', 'b', 'a']);

    await carry(tester, sticker('timed'), tester.getCenter(sticker('a')));
    expect(c.read(feedLayoutProvider).itemIds, ['timed', 'b', 'a']);
  });

  testWidgets('список едет у края и после того, как листок ушёл за экран',
      (tester) async {
    await open(tester, [
      for (var i = 0; i < 120; i++)
        item('i$i', DateTime(today.year, today.month, today.day - i)),
    ]);
    await showAllDates(tester);
    final scroll = find.byKey(const ValueKey('feed_dated_scroll'));
    double pixels() => tester
        .state<ScrollableState>(
          find.descendant(of: scroll, matching: find.byType(Scrollable)).first,
        )
        .position
        .pixels;

    final gesture = await tester.startGesture(tester.getCenter(sticker('i0')));
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.moveTo(Offset(40, tester.getBottomLeft(scroll).dy - 10));
    await tester.pump();
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(sticker('i0'), findsNothing);

    final before = pixels();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(pixels(), greaterThan(before));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  const rail = ValueKey('feed_day_rail');
  const cell = 36.0;
  const railX = 340.0;

  /// Приподнимает листок и чуть сдвигает: отсюда шкала отсчитывает дни.
  Future<(TestGesture, double)> lift(WidgetTester tester, Finder from) async {
    final start = tester.getCenter(from);
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.moveBy(const Offset(0, 1));
    await tester.pump();
    return (gesture, start.dy + 1);
  }

  DateTime dateOf(ProviderContainer c, String id) => c
      .read(memoryItemsControllerProvider)
      .firstWhere((record) => record.id == id)
      .memoryDate;

  testWidgets('приподнятый листок шкалу не открывает', (tester) async {
    await open(tester, [item('a', today)]);

    final gesture = await tester.startGesture(tester.getCenter(sticker('a')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(rail), findsNothing);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('sticker_move_a')), findsOneWidget);
  });

  for (final allDates in [true, false]) {
    testWidgets(
        'на шкале запись едет на день, которого в ленте нет '
        '(все записи: $allDates)', (tester) async {
      final c = await open(tester, [item('a', today)]);
      if (allDates) await showAllDates(tester);

      final (gesture, y) = await lift(tester, sticker('a'));
      await gesture.moveTo(Offset(railX, y));
      await tester.pumpAndSettle();
      expect(find.byKey(rail), findsOneWidget);
      expect(find.byType(FeedDayRailBubble), findsOneWidget);

      await gesture.moveBy(const Offset(0, cell * 2));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(dateOf(c, 'a'), DateTime(today.year, today.month, today.day - 2));
      expect(find.byType(FeedDayRailBubble), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('выше по шкале — позже, на своём дне ничего не меняется',
      (tester) async {
    final c = await open(tester, [item('a', today)]);
    await showAllDates(tester);

    var (gesture, y) = await lift(tester, sticker('a'));
    await gesture.moveTo(Offset(railX, y));
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(dateOf(c, 'a'), today);

    (gesture, y) = await lift(tester, sticker('a'));
    await gesture.moveTo(Offset(railX, y));
    await tester.pumpAndSettle();
    await gesture.moveBy(const Offset(0, -cell));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(dateOf(c, 'a'), DateTime(today.year, today.month, today.day + 1));
  });

  testWidgets('у края шкала едет дальше видимых дней', (tester) async {
    final c = await open(tester, [item('a', today)]);
    await showAllDates(tester);

    final (gesture, y) = await lift(tester, sticker('a'));
    await gesture.moveTo(Offset(railX, y));
    await tester.pumpAndSettle();
    await gesture
        .moveTo(Offset(railX, tester.getBottomRight(find.byKey(rail)).dy - 4));
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    final visibleDays = (800 - y) / cell;
    expect(
      today.difference(dateOf(c, 'a')).inDays,
      greaterThan(visibleDays.ceil() + 5),
    );
    expect(tester.takeException(), isNull);
  });

  test('шкала считает дни через границу месяца', () {
    final scale = FeedDayScale(
      ownDay: DateTime(2026, 10, 31),
      ownY: 100,
      cellExtent: 36,
    );
    expect(scale.indexAt(100), 0);
    expect(scale.indexAt(136), 1);
    expect(scale.indexAt(64), -1);
    expect(scale.dayOf(-1), DateTime(2026, 11, 1));
    expect(scale.dayOf(31), DateTime(2026, 9, 30));
    scale.shift = 72;
    expect(scale.indexAt(100), 2);
    expect(scale.centerOf(2), 100);
  });

  testWidgets('в ленте чем позже день, тем выше, внутри дня утро выше вечера',
      (tester) async {
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    final c = await open(tester, [
      item('old', other),
      item('evening', today, time: 1200),
      item('morning', today, time: 480),
      item('future', tomorrow),
    ]);
    await showAllDates(tester);

    expect(
      c.read(feedLayoutProvider).itemIds,
      ['future', 'morning', 'evening', 'old'],
    );
  });

  group('фокус на сегодняшнем дне', () {
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final scroll = find.byKey(const ValueKey('feed_dated_scroll'));

    testWidgets('сверху экрана сегодня, будущее выше него, прошлое ниже',
        (tester) async {
      await open(tester, [
        item('future', tomorrow),
        item('now', today),
        item('past', yesterday),
      ]);
      await showAllDates(tester);

      final top = tester.getTopLeft(scroll).dy;
      expect(tester.getRect(sticker('now')).top, greaterThanOrEqualTo(top));
      // Над точкой отсчёта и за краем экрана: Flutter такое не находит.
      expect(sticker('future'), findsNothing);
      expect(
        tester.getRect(sticker('past')).top,
        greaterThan(tester.getRect(sticker('now')).bottom),
      );

      await tester.drag(scroll, const Offset(0, 300));
      await tester.pumpAndSettle();
      expect(tester.getRect(sticker('future')).top, greaterThanOrEqualTo(top));
      expect(tester.takeException(), isNull);
    });

    testWidgets('в будущем записи дня идут в обычном порядке', (tester) async {
      await open(tester, [
        item('first', tomorrow, time: 480),
        item('second', tomorrow, time: 1200),
      ]);
      await showAllDates(tester);
      await tester.drag(scroll, const Offset(0, 300));
      await tester.pumpAndSettle();

      expect(
        tester.getRect(sticker('first')).left,
        lessThan(tester.getRect(sticker('second')).left),
      );
    });

    testWidgets('без записей на сегодня подпись дня всё равно на месте',
        (tester) async {
      final now = DateFormat.yMMMMEEEEd('ru').format(today);
      await open(tester, [item('past', yesterday)]);
      await showAllDates(tester);

      expect(find.textContaining(now.substring(1)), findsOneWidget);
    });
  });
}
