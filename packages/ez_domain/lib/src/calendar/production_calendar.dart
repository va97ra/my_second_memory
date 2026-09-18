import 'workday_progress.dart';

/// Federal Russian five-day working week. Independent of personal shifts
/// and commemorative holidays. Unknown years deliberately have no estimates.
enum ProductionDay {
  working,
  weekend,
  holiday,
  transferredDayOff,
  shortened,
  dayOff
}

extension ProductionDayRules on ProductionDay {
  bool get isWorkingDay =>
      this == ProductionDay.working || this == ProductionDay.shortened;
  bool get isDayOff => !isWorkingDay;
}

class ProductionYear {
  ProductionYear(this.year, Iterable<ProductionDay> days)
      : days = List.unmodifiable(days) {
    if (this.days.length !=
        DateTime.utc(year + 1).difference(DateTime.utc(year)).inDays) {
      throw const FormatException('Incomplete production year');
    }
  }
  final int year;
  final List<ProductionDay> days;

  ProductionDay day(DateTime date) =>
      days[DateTime.utc(year, date.month, date.day)
          .difference(DateTime.utc(year))
          .inDays];
}

class ProductionCalendar {
  const ProductionCalendar({this.yearData});
  final ProductionYear? yearData;

  // Government decree 24.09.2025 №1466 and Labour Code articles 95, 112.
  // https://publication.pravo.gov.ru/document/0001202509240023
  static const sourceUrl =
      'https://publication.pravo.gov.ru/document/0001202509240023';
  static const _holidays = {
    101,
    102,
    103,
    104,
    105,
    106,
    107,
    108,
    223,
    308,
    501,
    509,
    612,
    1104,
  };
  static const _transferred2026 = {109, 309, 511, 1231};
  static const _shortened2026 = {430, 508, 611, 1103};

  ProductionDay? day(DateTime date) {
    if (yearData?.year == date.year) return yearData!.day(date);
    if (date.year != 2026) return null;
    final key = date.month * 100 + date.day;
    if (_holidays.contains(key)) return ProductionDay.holiday;
    if (_transferred2026.contains(key)) return ProductionDay.transferredDayOff;
    if (_shortened2026.contains(key)) return ProductionDay.shortened;
    return date.weekday >= DateTime.saturday
        ? ProductionDay.weekend
        : ProductionDay.working;
  }

  ProductionMonth? month(DateTime date) {
    if (day(date) == null) return null;
    final days = DateTime(date.year, date.month + 1, 0).day;
    var working = 0;
    var shortened = 0;
    for (var d = 1; d <= days; d++) {
      switch (day(DateTime(date.year, date.month, d))) {
        case ProductionDay.working:
          working++;
        case ProductionDay.shortened:
          working++;
          shortened++;
        default:
          break;
      }
    }
    return ProductionMonth(working, days - working, shortened);
  }

  /// Calendar progress, not attendance: today has not finished yet.
  ProductionProgress? progress(DateTime monthDate,
          {required DateTime today, bool includeToday = false}) =>
      workdayProgress(monthDate,
          today: today,
          includeToday: includeToday,
          isWorkingDay: (date) => day(date)?.isWorkingDay);
}

class ProductionMonth {
  const ProductionMonth(this.workingDays, this.daysOff, this.shortenedDays);
  final int workingDays;
  final int daysOff;
  final int shortenedDays;

  double hours(int weeklyHours) =>
      workingDays * weeklyHours / 5 - shortenedDays;
}
