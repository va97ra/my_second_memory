import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shift_schedules/shift_schedules.dart';
import 'calendar_today_provider.dart';
import 'production_preferences.dart';

enum ProductionPeriod { week, month, year }

typedef ProductionPeriodQuery = ({DateTime date, ProductionPeriod period});
typedef PeriodProgressRow = ({String name, ProductionProgress? progress});
final productionPeriodProvider = Provider.autoDispose
    .family<List<PeriodProgressRow>, ProductionPeriodQuery>((ref, query) {
  final date = query.date;
  final start = switch (query.period) {
    ProductionPeriod.week =>
      DateTime.utc(date.year, date.month, date.day - date.weekday + 1),
    ProductionPeriod.month => DateTime.utc(date.year, date.month),
    ProductionPeriod.year => DateTime.utc(date.year),
  };
  final end = switch (query.period) {
    ProductionPeriod.week => start.add(const Duration(days: 7)),
    ProductionPeriod.month => DateTime.utc(date.year, date.month + 1),
    ProductionPeriod.year => DateTime.utc(date.year + 1),
  };
  final today = ref.watch(calendarTodayProvider);
  final includeToday = ref.watch(productionPreferencesProvider).includeToday;
  ProductionProgress? count(bool? Function(DateTime) works) =>
      workdayRangeProgress(start, end,
          today: today, includeToday: includeToday, isWorkingDay: works);
  return [
    for (final schedule in ref.watch(shiftSchedulesControllerProvider))
      if (schedule.isEnabled)
        (
          name: schedule.organizationName,
          progress: count(
              (d) => schedule.isWorkday(d) && !schedule.isVacationWorkday(d))
        )
  ];
});
