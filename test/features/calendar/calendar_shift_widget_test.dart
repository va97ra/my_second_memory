import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ezhednevnik_v2/src/app/app.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ezhednevnik_v2/src/features/security/state/security_provider.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/state/shift_schedules_controller.dart';
import 'package:ezhednevnik_v2/src/features/calendar/ui/widgets/shift_marks.dart';
import '../../support/widget_test_harness.dart';

void main() {
  useTestEnvironment();

  testWidgets('calendar shows shift colors and opens selected day',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final memoryRepository = FeedMemoryRepository();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    final secondWorkDay = today.add(const Duration(days: 1));
    final secondWorkDayKey =
        '${secondWorkDay.year}-${secondWorkDay.month.toString().padLeft(2, '0')}-'
        '${secondWorkDay.day.toString().padLeft(2, '0')}';
    final shiftRepository = FakeShiftScheduleRepository([
      ShiftSchedule(
        id: 'factory',
        organizationName: 'Завод',
        colorValue: 0xFF2563EB,
        startDate: today,
        workDays: 5,
        restDays: 2,
        vacations: [
          ShiftVacation(
            id: 'factory-vacation',
            startDate: today,
            durationDays: 1,
          ),
        ],
      ),
      ShiftSchedule(
        id: 'watch',
        organizationName: 'Вахта',
        colorValue: 0xFF16A34A,
        startDate: today,
        workDays: 1,
        restDays: 3,
      ),
    ]);

    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(memoryRepository),
          shiftScheduleRepositoryProvider.overrideWithValue(shiftRepository),
        ],
        child: const EzhednevnikV2App(),
      ),
    );

    await tester.pumpAndSettle();
    await openTab(tester, 'calendar');

    final cell = find.byKey(ValueKey('calendar_day_$dayKey'));
    expect(cell, findsOneWidget);
    final todayContainer = tester.widget<AnimatedContainer>(
      find.descendant(of: cell, matching: find.byType(AnimatedContainer)).first,
    );
    final todayDecoration = todayContainer.decoration! as BoxDecoration;
    // Сегодня отмечено чёрной обводкой, а не заливкой: в день открытия он же и
    // выбранный, и акцентная заливка съедала бы его собственную примету.
    expect(todayDecoration.border!.top.width, 3);
    expect((todayDecoration.border! as Border).top.color, Colors.black);
    expect(todayDecoration.boxShadow, isNotEmpty);
    // И крупным числом: другой приметы внутри ячейки у него нет.
    final todayNumber = tester.widget<Text>(
      find.descendant(of: cell, matching: find.text('${today.day}')),
    );
    expect(todayNumber.style?.fontSize, 17);
    expect(
      find.descendant(
        of: cell,
        matching: find.byKey(ValueKey('shift_marks_$dayKey')),
      ),
      findsOneWidget,
    );
    final factorySegment = find.descendant(
      of: cell,
      matching: find.byKey(const ValueKey('shift_segment_factory')),
    );
    expect(factorySegment, findsOneWidget);
    final factoryFill = find.descendant(
      of: factorySegment,
      matching: find.byType(ColoredBox),
    );
    expect(factoryFill, findsOneWidget);
    expect(
      tester.widget<ColoredBox>(factoryFill).color,
      const Color(0xFF2563EB),
    );
    // Цвет графика занимает полосу по верхней кромке, а не всю ячейку:
    // залитый целиком день пестрит и спорит с записями.
    final stripe = tester.getRect(factoryFill);
    final segment = tester.getRect(factorySegment);
    expect(stripe.height, ShiftMarks.stripeHeight);
    expect(stripe.top, segment.top);
    expect(stripe.height, lessThan(segment.height / 3));
    // По ширине полоса идёт во всю долю графика. Без этой проверки она может
    // схлопнуться в ноль и остаться невидимой, а высота — сойтись.
    expect(stripe.width, segment.width);
    expect(
      find.descendant(
        of: factorySegment,
        matching: find.byKey(
          ValueKey('vacation_ribbon_factory_$dayKey'),
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('vacation_ribbon_watch_$dayKey')),
      findsNothing,
    );

    final secondWorkCell =
        find.byKey(ValueKey('calendar_day_$secondWorkDayKey'));
    expect(secondWorkCell, findsOneWidget);
    expect(
      find.descendant(
        of: secondWorkCell,
        matching: find.byKey(ValueKey('shift_marks_$secondWorkDayKey')),
      ),
      findsOneWidget,
    );

    await tester.tap(cell);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(find.textContaining('Завод'), findsOneWidget);
    expect(find.textContaining('Вахта'), findsOneWidget);
  });
}
