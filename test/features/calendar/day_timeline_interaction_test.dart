import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/calendar/ui/widgets/day_timeline.dart';
import 'package:ezhednevnik_v2/src/features/calendar/ui/widgets/day_timeline_entry.dart';
import 'package:ezhednevnik_v2/src/features/calendar/ui/widgets/day_timeline_geometry.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/widget_test_harness.dart';

void main() {
  useTestEnvironment();
  for (final width in [320.0, 360.0, 600.0, 840.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('draft can be resized and opened at $width / $scale',
          (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        (int, int)? created;
        await tester.pumpWidget(ProviderScope(
            child: MaterialApp(
          theme: buildNotebookTheme(),
          home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                  body: DayTimeline(
                      items: const [],
                      onCreate: (start, end) => created = (start, end)))),
        )));
        await tester.pumpAndSettle();
        // Empty scale starts at 07:00; y=128 is 09:00.
        await tester.tapAt(const Offset(150, 130));
        await tester.pump();
        expect(find.text('09:00 – 10:00'), findsOneWidget);
        final handle = find
            .byWidgetPredicate(
                (w) => w is GestureDetector && w.onVerticalDragStart != null)
            .last;
        final gesture = await tester.startGesture(tester.getCenter(handle));
        await tester.pump(const Duration(milliseconds: 600));
        await gesture.moveBy(const Offset(0, 32));
        await gesture.up();
        await tester.pump();
        expect(find.text('09:00 – 10:30'), findsOneWidget);
        await tester.tapAt(const Offset(150, 155));
        await tester.pump();
        expect(created, (540, 630));
        expect(find.text('09:00 – 10:30'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
      'moving a record preserves duration and resizing preserves the opposite edge',
      (tester) async {
    final date = DateTime(2026, 9, 18);
    final repository = EmptyMemoryRepository()
      ..savedItems = [
        MemoryItem(
          id: 'task',
          title: 'Дело',
          type: MemoryType.task,
          memoryDate: date,
          createdAt: date,
          updatedAt: date,
          timeMinutes: 540,
          endMinutes: 600,
        )
      ];
    await tester.pumpWidget(testProviderScope(
      overrides: [memoryRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
          theme: buildNotebookTheme(),
          home: Scaffold(
            body: Consumer(
                builder: (context, ref, _) => DayTimeline(
                    items: ref.watch(memoryItemsControllerProvider),
                    onCreate: (_, __) {})),
          )),
    ));
    await tester.pumpAndSettle();
    final gesture =
        await tester.startGesture(tester.getCenter(find.text('Дело')));
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveBy(const Offset(0, 64));
    await tester.pump();
    expect(repository.savedItems.single.timeMinutes, 540);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(repository.savedItems.single.timeMinutes, 600);
    expect(repository.savedItems.single.endMinutes, 660);
    final handle = find
        .byWidgetPredicate(
            (w) => w is GestureDetector && w.onVerticalDragStart != null)
        .last;
    final resize = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 600));
    await resize.moveBy(const Offset(0, 32));
    await resize.up();
    await tester.pumpAndSettle();
    expect(repository.savedItems.single.timeMinutes, 600);
    expect(repository.savedItems.single.endMinutes, 690);
    expect(tester.takeException(), isNull);
  });

  /// Пустая шкала начинается с 07:00, поэтому 09:00 лежит на высоте 128,
  /// 10:00 — на 192. Флажки стоят у правого края рамки.
  const flagX = 296.0;

  Future<void> openDraft(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
      theme: buildNotebookTheme(),
      home: Scaffold(body: DayTimeline(items: const [], onCreate: (_, __) {})),
    )));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(150, 130));
    await tester.pump();
    expect(find.text('09:00 – 10:00'), findsOneWidget);
  }

  Future<void> holdAndMove(
    WidgetTester tester,
    Offset from,
    double dy,
  ) async {
    final gesture = await tester.startGesture(from);
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveBy(Offset(0, dy));
    await tester.pump();
    await gesture.up();
    await tester.pump();
  }

  testWidgets('флажок ловит палец и за границей рамки', (tester) async {
    await openDraft(tester);
    await holdAndMove(tester, const Offset(flagX, 192 + 20), 32);
    expect(find.text('09:00 – 10:30'), findsOneWidget);
  });

  testWidgets('верхний флажок двигает начало и тоже за границей рамки',
      (tester) async {
    await openDraft(tester);
    await holdAndMove(tester, const Offset(flagX, 128 - 20), -32);
    expect(find.text('08:30 – 10:00'), findsOneWidget);
  });

  testWidgets('рамка растягивается по минуте', (tester) async {
    await openDraft(tester);
    await holdAndMove(
      tester,
      const Offset(flagX, 192 + 8),
      dayTimelineOffsetOf(17),
    );
    expect(find.text('09:00 – 10:17'), findsOneWidget);
  });

  testWidgets('узкая рамка не сжимается меньше четверти часа', (tester) async {
    await openDraft(tester);
    await holdAndMove(tester, const Offset(flagX, 192 + 8), -200);
    expect(find.text('09:00 – 09:15'), findsOneWidget);
  });

  testWidgets('новую рамку можно перетащить целиком', (tester) async {
    await openDraft(tester);
    await holdAndMove(tester, const Offset(150, 160), 64);
    expect(find.text('10:00 – 11:00'), findsOneWidget);
  });

  group('запись на шкале', () {
    final date = DateTime(2026, 9, 18);
    MemoryItem record({int end = 600, String body = ''}) => MemoryItem(
          id: 'task',
          title: 'Дело',
          body: body,
          type: MemoryType.task,
          memoryDate: date,
          createdAt: date,
          updatedAt: date,
          timeMinutes: 540,
          endMinutes: end,
        );

    Future<EmptyMemoryRepository> open(
      WidgetTester tester,
      MemoryItem item,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = EmptyMemoryRepository()..savedItems = [item];
      await tester.pumpWidget(testProviderScope(
        overrides: [memoryRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
            theme: buildNotebookTheme(),
            home: Scaffold(
              body: Consumer(
                  builder: (context, ref, _) => DayTimeline(
                      items: ref.watch(memoryItemsControllerProvider),
                      onCreate: (_, __) {})),
            )),
      ));
      await tester.pumpAndSettle();
      return repository;
    }

    Future<void> select(WidgetTester tester, Finder card) async {
      final hold = await tester.startGesture(tester.getCenter(card));
      await tester.pump(const Duration(milliseconds: 600));
      await hold.up();
      await tester.pumpAndSettle();
    }

    testWidgets('растяжение записывается один раз, когда отпустили палец',
        (tester) async {
      final repository = await open(tester, record());
      await select(tester, find.text('Дело'));

      final handle = find
          .byWidgetPredicate(
              (w) => w is GestureDetector && w.onVerticalDragStart != null)
          .last;
      final resize = await tester.startGesture(tester.getCenter(handle));
      await tester.pump(const Duration(milliseconds: 600));
      await resize.moveBy(Offset(0, dayTimelineOffsetOf(7)));
      await tester.pump();
      expect(repository.savedItems.single.endMinutes, 600);
      expect(find.text('09:00 – 10:07'), findsOneWidget);

      await resize.up();
      await tester.pumpAndSettle();
      expect(repository.savedItems.single.endMinutes, 607);
      expect(find.text('09:00 – 10:07'), findsNothing);
    });

    testWidgets('длинный текст виден в большой карточке целиком',
        (tester) async {
      const ending = 'самый конец длинного текста';
      await open(
        tester,
        record(
          end: 13 * 60,
          body: 'Первая мысль про склад и кабель. Вторая мысль про оплату '
              'счёта в банке. Третья мысль про доставку щита. $ending',
        ),
      );

      expect(
        find.textContaining(ending, findRichText: true),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('нажатие поднимает нижнюю запись наверх и даёт её растянуть',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      MemoryItem at(String id, int start, int end) => record().copyWith(
            id: id,
            title: id,
            timeMinutes: start,
            endMinutes: end,
          );
      final repository = EmptyMemoryRepository()
        ..savedItems = [at('outer', 540, 720), at('inner', 600, 660)];
      await tester.pumpWidget(testProviderScope(
        overrides: [memoryRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
            theme: buildNotebookTheme(),
            home: Scaffold(
              body: Consumer(
                  builder: (context, ref, _) => DayTimeline(
                      items: ref.watch(memoryItemsControllerProvider),
                      onCreate: (_, __) {})),
            )),
      ));
      await tester.pumpAndSettle();
      String top() => tester
          .widgetList<DayTimelineEntry>(find.byType(DayTimelineEntry))
          .last
          .block
          .item
          .id;
      expect(top(), 'inner');

      await tester.tap(find.text('outer'));
      await tester.pumpAndSettle();
      expect(top(), 'outer');

      final handle = find
          .byWidgetPredicate(
              (w) => w is GestureDetector && w.onVerticalDragStart != null)
          .last;
      final resize = await tester.startGesture(tester.getCenter(handle));
      await tester.pump(const Duration(milliseconds: 600));
      await resize.moveBy(Offset(0, dayTimelineOffsetOf(10)));
      await resize.up();
      await tester.pumpAndSettle();
      expect(
        repository.savedItems.firstWhere((i) => i.id == 'outer').endMinutes,
        730,
      );
      expect(top(), 'outer');
      expect(tester.takeException(), isNull);
    });

    testWidgets('запись на четверть часа остаётся одной строкой',
        (tester) async {
      await open(tester, record(end: 555, body: 'Дело и ещё много слов тут'));
      expect(tester.takeException(), isNull);
    });
  });
}
