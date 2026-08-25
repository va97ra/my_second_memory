import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:ezhednevnik_v2/src/app/app.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ezhednevnik_v2/src/features/security/state/security_provider.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/state/shift_schedules_controller.dart';
import '../../support/widget_test_harness.dart';

void main() {
  useTestEnvironment();

  testWidgets('calendar changes month with horizontal swipes', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
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

    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final nextMonth = DateTime(now.year, now.month + 1);
    String monthLabel(DateTime month) {
      final value = DateFormat('LLLL', 'ru').format(month);
      return '${value[0].toUpperCase()}${value.substring(1)} ${month.year}';
    }

    final swipeArea = find.byKey(
      const ValueKey('calendar_month_swipe_area'),
    );
    expect(find.text(monthLabel(currentMonth)), findsOneWidget);

    await tester.drag(swipeArea, const Offset(-160, 0));
    await tester.pump();
    final incomingPage = find.byKey(
      const ValueKey('calendar_page_incoming'),
    );
    expect(
      find.byKey(const ValueKey('calendar_page_outgoing')),
      findsOneWidget,
    );
    expect(incomingPage, findsOneWidget);
    final incomingStartX =
        tester.widget<Transform>(incomingPage).transform.getTranslation().x;
    await tester.pump(const Duration(milliseconds: 100));
    final incomingMovedX =
        tester.widget<Transform>(incomingPage).transform.getTranslation().x;
    expect(incomingMovedX, lessThan(incomingStartX));
    expect(incomingMovedX, greaterThan(0));
    await tester.pumpAndSettle();
    expect(find.text(monthLabel(nextMonth)), findsOneWidget);

    await tester.drag(swipeArea, const Offset(160, 0));
    await tester.pumpAndSettle();
    expect(find.text(monthLabel(currentMonth)), findsOneWidget);
  });

  testWidgets('calendar changes year with animated vertical swipes',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
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

    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final nextYear = DateTime(now.year + 1, now.month);

    final swipeArea = find.byKey(
      const ValueKey('calendar_month_swipe_area'),
    );
    await tester.drag(swipeArea, const Offset(0, -180));
    await tester.pump();
    final incomingPage = find.byKey(
      const ValueKey('calendar_page_incoming'),
    );
    expect(
      find.byKey(const ValueKey('calendar_page_outgoing')),
      findsOneWidget,
    );
    expect(incomingPage, findsOneWidget);
    final incomingStartY =
        tester.widget<Transform>(incomingPage).transform.getTranslation().y;
    await tester.pump(const Duration(milliseconds: 100));
    final incomingMovedY =
        tester.widget<Transform>(incomingPage).transform.getTranslation().y;
    expect(incomingMovedY, lessThan(incomingStartY));
    expect(incomingMovedY, greaterThan(0));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('calendar_month_label')))
          .data,
      contains('${nextYear.year}'),
    );

    await tester.drag(swipeArea, const Offset(0, 180));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('calendar_month_label')))
          .data,
      contains('${currentMonth.year}'),
    );
  });
}
