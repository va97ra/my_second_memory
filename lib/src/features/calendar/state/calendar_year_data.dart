import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../memory_items/memory_items.dart';
import '../../recurrence/recurrence.dart';
import '../../shift_schedules/shift_schedules.dart';
import 'calendar_month_data.dart';
import 'calendar_preferences_controller.dart';
import 'holiday_providers.dart';

/// Двенадцать месяцев года для годового вида, по порядку с января.
///
/// Записи года берутся одним запросом, а каждый месяц собирается тем же
/// [CalendarMonthData.build], что и большая страница: миниатюра не может
/// показать день не так, как его показывает месяц.
final calendarYearDataProvider =
    Provider.family<List<CalendarMonthData>, int>((ref, year) {
  final items = ref.watch(
    calendarItemsForRangeProvider(
      RecurrenceRange(DateTime(year), DateTime(year, 12, 31)),
    ),
  );
  final byMonth = List.generate(12, (_) => <MemoryItem>[]);
  for (final item in items) {
    byMonth[item.memoryDate.month - 1].add(item);
  }
  final alarmDays = ref.watch(
    memoryItemsIndexProvider.select((index) => index.activeReminderDays),
  );
  final schedules = ref.watch(shiftSchedulesControllerProvider);
  final holidayService = ref.watch(holidayCalendarServiceProvider);
  final showHolidays = ref.watch(appHolidaysProvider);

  return [
    for (var month = 1; month <= 12; month++)
      CalendarMonthData.build(
        month: DateTime(year, month),
        items: byMonth[month - 1],
        persistedAlarmDays: alarmDays,
        shiftSchedules: schedules,
        holidayService: holidayService,
        showHolidays: showHolidays,
      ),
  ];
});
