part of '../widget_test.dart';

void registerCalendarShiftWidgetTests() {
  testWidgets('calendar shows shift colors and opens selected day',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final memoryRepository = _FeedMemoryRepository();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    final secondWorkDay = today.add(const Duration(days: 1));
    final secondWorkDayKey =
        '${secondWorkDay.year}-${secondWorkDay.month.toString().padLeft(2, '0')}-'
        '${secondWorkDay.day.toString().padLeft(2, '0')}';
    final shiftRepository = _FakeShiftScheduleRepository([
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
          securityServiceProvider.overrideWithValue(_UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(memoryRepository),
          shiftScheduleRepositoryProvider.overrideWithValue(shiftRepository),
        ],
        child: const EzhednevnikV2App(),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Календарь'));
    await tester.pumpAndSettle();

    final cell = find.byKey(ValueKey('calendar_day_$dayKey'));
    expect(cell, findsOneWidget);
    final todayContainer = tester.widget<AnimatedContainer>(
      find.descendant(of: cell, matching: find.byType(AnimatedContainer)).first,
    );
    final todayDecoration = todayContainer.decoration! as BoxDecoration;
    expect(todayDecoration.border!.top.width, 2.5);
    expect(todayDecoration.boxShadow, isNotEmpty);
    expect(
      find.descendant(
        of: cell,
        matching: find.byKey(ValueKey('shift_fill_$dayKey')),
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
        matching: find.byKey(ValueKey('shift_fill_$secondWorkDayKey')),
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
