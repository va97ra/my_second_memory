/// Адреса дня календаря и праздников этого дня.
///
/// Дата в адресе пишется одним способом во всём приложении: адрес собирали в
/// четырёх местах каждое по-своему, и разбор в маршрутизаторе держался на
/// том, что все четыре случайно совпадали.
library;

String calendarDayLocation(DateTime date) =>
    '/calendar/day?date=${_dateParameter(date)}';

String holidaysLocation(DateTime date) =>
    '/calendar/holidays?date=${_dateParameter(date)}';

/// День из адреса, записанный [calendarDayLocation]; null — дня в адресе
/// нет или он нечитаем.
DateTime? dateInLocation(Uri location) {
  final raw = location.queryParameters['date'];
  return raw == null ? null : DateTime.tryParse(raw);
}

String _dateParameter(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year.toString().padLeft(4, '0')}-$month-$day';
}
