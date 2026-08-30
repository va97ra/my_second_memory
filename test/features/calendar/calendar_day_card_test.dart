import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ezhednevnik_v2/src/app/app.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ezhednevnik_v2/src/features/security/state/security_provider.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/state/shift_schedules_controller.dart';
import '../../support/widget_test_harness.dart';

void main() {
  useTestEnvironment();

  testWidgets('calendar day card can be completed and archived',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = FeedMemoryRepository();
    final now = DateTime.now();

    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(repository),
          shiftScheduleRepositoryProvider.overrideWithValue(
            FakeShiftScheduleRepository(),
          ),
        ],
        child: const EzhednevnikV2App(),
      ),
    );

    await tester.pumpAndSettle();
    await openTab(tester, 'calendar');
    final dayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    await tester.tap(find.byKey(ValueKey('calendar_day_$dayKey')));
    await tester.pumpAndSettle();

    expect(
      tester
          .getSize(find.byKey(const ValueKey('memory_card_today-plan')))
          .height,
      108,
    );

    await tester.tap(
      find.byKey(const ValueKey('memory_card_done_today-plan')),
    );
    await tester.pumpAndSettle();
    expect(
      repository.savedItems
          .firstWhere((item) => item.id == 'today-plan')
          .isDone,
      isTrue,
    );

    await tester.tap(
      find.byKey(const ValueKey('memory_card_archive_today-plan')),
    );
    await tester.pumpAndSettle();
    expect(
      repository.savedItems
          .firstWhere((item) => item.id == 'today-plan')
          .isArchived,
      isTrue,
    );
    // Из архива запись видна только в архиве: с экрана дня она уходит и
    // возвращается лишь восстановлением.
    expect(find.text('План на сегодня'), findsNothing);
  });
}
