import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/app/app.dart';
import 'package:ezhednevnik_v2/src/features/home_feed/state/feed_layout_provider.dart';
import 'package:ezhednevnik_v2/src/features/home_feed/state/feed_providers.dart';
import 'package:ezhednevnik_v2/src/features/home_feed/ui/widgets/feed_group_divider.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ezhednevnik_v2/src/features/security/security.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/widget_test_harness.dart';

void main() {
  useTestEnvironment();
  testWidgets('a query opens all saved dates and closing restores the day',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final today = DateTime.now();
    MemoryItem item(String id, DateTime day,
            {bool archived = false, bool undated = false}) =>
        MemoryItem(
            id: id,
            type: MemoryType.task,
            title: id,
            body: '',
            memoryDate: day,
            status: archived ? MemoryStatus.archived : MemoryStatus.active,
            isUndated: undated,
            createdAt: today,
            updatedAt: today);
    final repo = EmptyMemoryRepository()
      ..savedItems = [
        item('today', today),
        item('past', DateTime(2020, 1, 2)),
        item('future', DateTime(2030, 1, 2)),
        item('archive', today, archived: true),
        item('note', today, undated: true)
      ];
    await tester.pumpWidget(testProviderScope(overrides: [
      memoryRepositoryProvider.overrideWithValue(repo),
      securityServiceProvider.overrideWithValue(UnlockedSecurityService())
    ], child: const EzhednevnikV2App()));
    await tester.pumpAndSettle();
    await openTab(tester, 'feed');
    final button = find.byKey(const ValueKey('feed_search'));
    expect(button, findsOneWidget);
    final c = ProviderScope.containerOf(tester.element(button));
    final anchor = c.read(feedViewProvider).anchorDate;
    await tester.tap(button);
    await tester.pumpAndSettle();
    // Пустая строка ничего не ищет: под ней остаётся открытый день.
    expect(c.read(feedViewProvider).allDates, isFalse);
    expect(c.read(feedLayoutProvider).itemIds, ['today']);

    // Буква есть в записке, но записка без даты в поиск по датам не входит.
    await tester.enterText(
        find.byKey(const ValueKey('feed_search_field')), 't');
    await tester.pumpAndSettle();
    expect(c.read(feedViewProvider).allDates, isTrue);
    final layout = c.read(feedLayoutProvider);
    expect(layout.itemIds, ['past', 'today', 'future']);
    expect(layout.groups.length, 3);
    expect(find.byType(FeedGroupDivider), findsWidgets);
    expect(find.byKey(const ValueKey('feed_section_allDates')), findsNothing);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(c.read(feedLayoutProvider).itemIds, ['today']);
    expect(c.read(feedViewProvider).anchorDate, anchor);
    expect(tester.takeException(), isNull);
  });
}
