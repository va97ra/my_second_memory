import 'package:ez_domain/ez_domain.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ezhednevnik_v2/src/features/calendar/state/day_shift_progress_provider.dart';
import 'package:ezhednevnik_v2/src/features/calendar/ui/calendar_day_screen.dart';
import 'package:ezhednevnik_v2/src/features/calendar/ui/widgets/day_timeline.dart';
import 'package:ezhednevnik_v2/src/features/calendar/ui/widgets/working_shift_chips.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/state/shift_schedules_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/widget_test_harness.dart';

ShiftSchedule schedule(String id, int start, {bool vacation = false}) =>
    ShiftSchedule(
      id: id,
      organizationName: '$id — длинное название организации и подразделения',
      colorValue: 0xFF2563EB,
      startDate: DateTime(2026, 9, start),
      workDays: 1,
      restDays: 3,
      vacations: vacation
          ? [
              ShiftVacation(
                  id: 'v', startDate: DateTime(2026, 9, 19), durationDays: 1)
            ]
          : [],
    );

void main() {
  useTestEnvironment();
  test('selected date chooses its own schedule and excludes vacation',
      () async {
    final controller = ShiftSchedulesController(FakeShiftScheduleRepository([
      schedule('Консалтинг', 3),
      schedule('Яндекс', 4),
    ]));
    await controller.load();
    final container = ProviderContainer(overrides: [
      shiftSchedulesControllerProvider.overrideWith((ref) => controller),
    ]);
    addTearDown(container.dispose);
    expect(container.read(dayShiftProgressProvider(DateTime(2026, 9, 18))),
        isEmpty);
    final tomorrow =
        container.read(dayShiftProgressProvider(DateTime(2026, 9, 19))).single;
    expect(tomorrow.schedule.id, 'Консалтинг');
    expect((tomorrow.progress.elapsed, tomorrow.progress.total), (4, 7));
    expect(
        container
            .read(dayShiftProgressProvider(DateTime(2026, 9, 20)))
            .single
            .schedule
            .id,
        'Яндекс');
    await controller.update(schedule('Консалтинг', 3, vacation: true));
    final holiday =
        container.read(dayShiftProgressProvider(DateTime(2026, 9, 19))).single;
    expect(holiday.vacation, true);
    expect((holiday.progress.elapsed, holiday.progress.total), (4, 6));
  });

  testWidgets('day details fit narrow screens and leave the timeline usable',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final width in [320.0, 360.0, 600.0, 840.0]) {
      for (final scale in [1.0, 1.3, 2.0]) {
        await tester.binding.setSurfaceSize(Size(width, 740));
        await tester.pumpWidget(testProviderScope(
            overrides: [
              shiftScheduleRepositoryProvider
                  .overrideWithValue(FakeShiftScheduleRepository([
                schedule('Консалтинг', 3),
                schedule('Вторая работа', 3),
                schedule('Яндекс', 4),
              ])),
            ],
            child: MaterialApp(
              theme: buildNotebookTheme(brightness: Brightness.light),
              locale: const Locale('ru'),
              supportedLocales: const [Locale('ru')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!),
              home: CalendarDayScreen(date: DateTime(2026, 9, 19)),
            )));
        await tester.pumpAndSettle();
        expect(find.text('Смена 5 из 7 в этом месяце'), findsNWidgets(2));
        expect(find.textContaining('Яндекс'), findsNothing);
        expect(
            tester.getSize(find.byType(DayTimeline)).height, greaterThan(200));
        final scroller = find.descendant(
            of: find.byType(WorkingShiftChips),
            matching: find.byType(SingleChildScrollView));
        await tester.drag(scroller, const Offset(0, -250));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$width / $scale');
        await tester.pumpWidget(const SizedBox());
      }
    }
  });
}
