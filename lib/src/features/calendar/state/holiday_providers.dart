import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'calendar_preferences_controller.dart';

/// Доставка доменного сервиса праздников в дерево виджетов.
final holidayCalendarServiceProvider = Provider<HolidayCalendarService>(
  (ref) => HolidayCalendarService(),
);

/// Праздники дня — ровно те, что человек попросил показывать.
///
/// Решение принимается здесь одно на всех: и карточка на экране дня, и полный
/// список открываются из одного источника.
final holidaysForDayProvider =
    Provider.family<List<HolidayOccurrence>, DateTime>((ref, date) {
  if (!ref.watch(appHolidaysProvider)) return const <HolidayOccurrence>[];
  return ref.watch(holidayCalendarServiceProvider).holidaysForDate(
        date,
        withObservances: ref.watch(appObservancesProvider),
      );
});
