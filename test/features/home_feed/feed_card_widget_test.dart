import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ezhednevnik_v2/src/app/app.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ezhednevnik_v2/src/features/security/state/security_provider.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/state/shift_schedules_controller.dart';
import '../../support/widget_test_harness.dart';

void main() {
  useTestEnvironment();

  testWidgets('feed filter shows selected record type only', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(FeedMemoryRepository()),
          shiftScheduleRepositoryProvider.overrideWithValue(
            FakeShiftScheduleRepository(),
          ),
        ],
        child: const EzhednevnikV2App(),
      ),
    );

    await tester.pumpAndSettle();
    await openTab(tester, 'feed');

    await tester.tap(find.byKey(const ValueKey('feed_filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Проект').last);
    await tester.pumpAndSettle();

    expect(find.text('Проект'), findsWidgets);
    expect(find.text('Ежедневник V2'), findsWidgets);
    expect(find.text('План на сегодня'), findsNothing);
    expect(find.text('Вчерашняя заметка'), findsNothing);

    await openTab(tester, 'calendar');
    await openTab(tester, 'feed');

    expect(find.text('Проект'), findsWidgets);
    expect(find.text('План на сегодня'), findsNothing);
  });
}
