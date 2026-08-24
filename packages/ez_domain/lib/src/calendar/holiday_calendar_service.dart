import 'holiday_fixed_table.dart';
import 'holiday_movable_table.dart';
import 'holiday_occurrence.dart';

class HolidayCalendarService {
  final Map<int, List<HolidayOccurrence>> _yearCache = {};
  final Map<int, List<HolidayOccurrence>> _dateCache = {};

  List<HolidayOccurrence> holidaysForDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final key =
        normalized.year * 10000 + normalized.month * 100 + normalized.day;
    return _dateCache.putIfAbsent(
      key,
      () => List.unmodifiable(
        _holidaysForYear(normalized.year).where(
          (holiday) => holiday.date == normalized,
        ),
      ),
    );
  }

  List<HolidayOccurrence> holidaysForRange(DateTime start, DateTime end) {
    final first = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    final result = <HolidayOccurrence>[];
    for (var year = first.year; year <= last.year; year++) {
      for (final holiday in _holidaysForYear(year)) {
        if (!holiday.date.isBefore(first) && !holiday.date.isAfter(last)) {
          result.add(holiday);
        }
      }
    }
    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  List<HolidayOccurrence> _holidaysForYear(int year) {
    return _yearCache.putIfAbsent(
      year,
      () => List.unmodifiable(_buildHolidaysForYear(year)),
    );
  }

  List<HolidayOccurrence> _buildHolidaysForYear(int year) {
    return [
      ...fixedHolidays.map((definition) => definition.occurrence(year)),
      ...movableHolidays(year, orthodoxEaster(year)),
    ];
  }
}

/// Дата православной Пасхи: александрийская пасхалия, приведённая к
/// григорианскому календарю.
DateTime orthodoxEaster(int year) {
  final a = year % 4;
  final b = year % 7;
  final c = year % 19;
  final d = (19 * c + 15) % 30;
  final e = (2 * a + 4 * b - d + 34) % 7;
  final month = (d + e + 114) ~/ 31;
  final day = (d + e + 114) % 31 + 1;
  return DateTime(year, month, day).add(const Duration(days: 13));
}
