/// ISO 8601: Monday starts the week; week 1 contains January 4.
/// UTC construction keeps daylight-saving transitions out of date arithmetic.
({int year, int number}) isoWeek(DateTime date) {
  final day = DateTime.utc(date.year, date.month, date.day);
  final thursday = day.add(Duration(days: DateTime.thursday - day.weekday));
  final first = DateTime.utc(thursday.year, 1, 4);
  final firstThursday =
      first.add(Duration(days: DateTime.thursday - first.weekday));
  return (
    year: thursday.year,
    number: thursday.difference(firstThursday).inDays ~/ 7 + 1
  );
}
