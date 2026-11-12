import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/calendar_today_provider.dart';
import '../../state/calendar_year_data.dart';
import '../../state/production_calendar_provider.dart';
import '../../state/production_preferences.dart';
import 'calendar_mini_month.dart';
import 'calendar_year_geometry.dart';

/// Страница года: двенадцать маленьких месяцев, по три в ряд в портрете и по
/// четыре в ландшафте.
///
/// Данные года читаются здесь одной подпиской, а не в каждом дне: дней на
/// странице больше пятисот.
class CalendarYearGrid extends ConsumerWidget {
  const CalendarYearGrid({
    super.key,
    required this.year,
    required this.locale,
    required this.onOpenMonth,
  });

  final int year;
  final String locale;
  final ValueChanged<DateTime> onOpenMonth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final months = ref.watch(calendarYearDataProvider(year));
    final productionDays = ref.watch(productionCalendarProvider(year)).calendar;
    final highlight =
        ref.watch(productionPreferencesProvider.select((s) => s.highlight));
    final today = ref.watch(calendarTodayProvider);

    return LayoutBuilder(
      key: ValueKey('calendar_year_grid_$year'),
      builder: (context, constraints) {
        final geometry = CalendarYearGeometry(constraints.biggest);
        return Stack(
          children: [
            for (var index = 0; index < 12; index++)
              Positioned.fromRect(
                rect: geometry.monthRect(index + 1),
                child: CalendarMiniMonth(
                  key: ValueKey('calendar_mini_month_${year}_${index + 1}'),
                  month: DateTime(year, index + 1),
                  locale: locale,
                  data: months[index],
                  productionDays: productionDays,
                  highlight: highlight,
                  today: today,
                  onOpen: () => onOpenMonth(DateTime(year, index + 1)),
                ),
              ),
          ],
        );
      },
    );
  }
}
