import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/calendar/ui/widgets/day_timeline.dart';
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
          theme: buildScreenTheme(cosmosColors),
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
          theme: buildScreenTheme(cosmosColors),
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
}
