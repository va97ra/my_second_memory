import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/app/app.dart';
import 'package:ezhednevnik_v2/src/features/home_feed/state/feed_layout_provider.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ezhednevnik_v2/src/features/security/security.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
