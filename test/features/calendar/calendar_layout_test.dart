import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ezhednevnik_v2/src/app/app.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ezhednevnik_v2/src/features/security/state/security_provider.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/state/shift_schedules_controller.dart';
import '../../support/widget_test_harness.dart';

void main() {
  useTestEnvironment();

  testWidgets('calendar fills portrait and scrolls only in short landscape',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
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
    await openTab(tester, 'calendar');
    expect(
      find.byKey(const ValueKey('calendar_landscape_scroll')),
      findsNothing,
    );
    final gridBottom = tester
        .getBottomRight(find.byKey(const ValueKey('calendar_month_grid')))
        .dy;
    final hintTop =
        tester.getTopLeft(find.byKey(const ValueKey('calendar_hint'))).dy;
    expect(hintTop - gridBottom, closeTo(7, 0.1));

    await tester.binding.setSurfaceSize(const Size(900, 430));
    await tester.pumpAndSettle();
    final calendarScrollView =
        find.byKey(const ValueKey('calendar_landscape_scroll'));
    expect(
      tester.widget<CustomScrollView>(calendarScrollView).physics,
      isA<ClampingScrollPhysics>(),
    );
    final scrollable = find.descendant(
      of: calendarScrollView,
      matching: find.byType(Scrollable),
    );
    final positionBefore =
        tester.state<ScrollableState>(scrollable.first).position.pixels;
    await tester.drag(calendarScrollView, const Offset(0, -140));
    await tester.pumpAndSettle();
    final positionAfter =
        tester.state<ScrollableState>(scrollable.first).position.pixels;
    expect(positionAfter, greaterThan(positionBefore));

    await tester.binding.setSurfaceSize(const Size(1200, 800));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('calendar_landscape_scroll')),
      findsNothing,
    );
  });
}
