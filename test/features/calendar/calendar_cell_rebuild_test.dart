import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/app/app.dart';
import 'package:ezhednevnik_v2/src/features/calendar/ui/widgets/calendar_day_cell.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ezhednevnik_v2/src/features/security/security.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/widget_test_harness.dart';

void main() {
  useTestEnvironment();

  testWidgets('правка записи перерисовывает одну ячейку, а не весь месяц',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final now = DateTime.now();
    MemoryItem item(String id, int day) => MemoryItem(
          id: id,
          type: MemoryType.task,
          title: id,
          body: id,
          memoryDate: DateTime(now.year, now.month, day),
          createdAt: now,
          updatedAt: now,
        );
    final repository = EmptyMemoryRepository()
      ..savedItems = [item('first', 10), item('second', 20)];

    await tester.pumpWidget(testProviderScope(overrides: [
      memoryRepositoryProvider.overrideWithValue(repository),
      securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
    ], child: const EzhednevnikV2App()));
    await tester.pumpAndSettle();
    await openTab(tester, 'calendar');

    final rebuilt = <DateTime>[];
    debugOnRebuildDirtyWidget = (element, _) {
      final widget = element.widget;
      if (widget is CalendarDayCell) rebuilt.add(widget.date);
    };
    addTearDown(() => debugOnRebuildDirtyWidget = null);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(CalendarDayCell).first),
    );
    await container
        .read(memoryItemsControllerProvider.notifier)
        .toggleDone('first');
    await tester.pumpAndSettle();

    expect(rebuilt.toSet(), {DateTime(now.year, now.month, 10)});
  });
}
