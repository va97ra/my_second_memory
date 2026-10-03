import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/calendar/state/calendar_today_provider.dart';
import 'package:ezhednevnik_v2/src/features/calendar/state/production_period_provider.dart';
import 'package:ezhednevnik_v2/src/features/calendar/state/production_preferences.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/shift_schedules.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../support/widget_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('enabled schedules automatically count each period excluding vacation',
      () async {
    SharedPreferences.setMockInitialValues({});
    final schedules = ShiftSchedulesController(FakeShiftScheduleRepository([
      ShiftSchedule(
          id: 'a',
          organizationName: 'A',
          colorValue: 0,
          startDate: DateTime(2026, 9, 1),
          workDays: 1,
          restDays: 1,
          vacations: [
            ShiftVacation(
                id: 'v', startDate: DateTime(2026, 9, 3), durationDays: 1)
          ]),
      ShiftSchedule(
          id: 'b',
          organizationName: 'B',
          colorValue: 0,
          startDate: DateTime(2026, 9, 1),
          workDays: 1,
          restDays: 2,
          isEnabled: false),
    ]));
    await schedules.load();
    final c = ProviderContainer(overrides: [
      shiftSchedulesControllerProvider.overrideWith((ref) => schedules),
      calendarTodayProvider.overrideWithValue(DateTime(2026, 9, 5)),
    ]);
    addTearDown(c.dispose);
    final month = productionPeriodProvider(
        (date: DateTime(2026, 9, 6), period: ProductionPeriod.month));
    expect(c.read(month).length, 1);
    expect(c.read(month).single.name, 'A');
    expect((
      c.read(month).single.progress!.elapsed,
      c.read(month).single.progress!.total
    ), (
      1,
      14
    ));
    await c
        .read(productionPreferencesProvider.notifier)
        .update(includeToday: true);
    expect(c.read(month).single.progress!.elapsed, 2);
    final week = c
        .read(productionPeriodProvider(
            (date: DateTime(2026, 9, 6), period: ProductionPeriod.week)))
        .single
        .progress!;
    expect((week.elapsed, week.total), (2, 2));
    final year = c
        .read(productionPeriodProvider(
            (date: DateTime(2026, 9, 6), period: ProductionPeriod.year)))
        .single
        .progress!;
    expect(year.total, greaterThan(14));
    expect(year.elapsed, 2);
  });
}
