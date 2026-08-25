import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the month grid never sees international observances', () {
    final service = HolidayCalendarService();
    // 6 июля — только Всемирный день поцелуя, официального праздника в этот
    // день нет: сетка месяца должна остаться пустой.
    expect(service.holidaysForDate(DateTime(2026, 7, 6)), isEmpty);

    // 8 июля — День семьи, любви и верности: ему лента положена.
    final official = service.holidaysForDate(DateTime(2026, 7, 8));
    expect(official, isNotEmpty);
    expect(official.every((holiday) => holiday.isOfficial), isTrue);
  });

  test('the day view sees them when it asks', () {
    final service = HolidayCalendarService();
    final all = service.holidaysForDate(
      DateTime(2026, 7, 6),
      withObservances: true,
    );

    expect(all.map((holiday) => holiday.id), contains('obs_kiss'));
    expect(
      all.firstWhere((holiday) => holiday.id == 'obs_kiss').category,
      HolidayCategory.observance,
    );
  });

  test('a range keeps the two layers apart', () {
    final service = HolidayCalendarService();
    final start = DateTime(2026, 12, 1);
    final end = DateTime(2026, 12, 31);
    final official = service.holidaysForRange(start, end);
    final all = service.holidaysForRange(start, end, withObservances: true);

    expect(official.length, lessThan(all.length));
    expect(official.every((holiday) => holiday.isOfficial), isTrue);
  });

  test('every observance has its own identifier', () {
    final ids = observanceHolidays.map((holiday) => holiday.id).toList();

    expect(ids.toSet().length, ids.length);
  });

  test('an observance falls on a real date', () {
    for (final holiday in observanceHolidays) {
      final date = holiday.occurrence(2026).date;
      expect(date.month, holiday.month, reason: holiday.id);
      expect(date.day, holiday.day, reason: holiday.id);
    }
  });
  test('the day the user asked about is no longer empty', () {
    final service = HolidayCalendarService();
    final day = service.holidaysForDate(
      DateTime(2026, 8, 25),
      withObservances: true,
    );

    expect(day, isNotEmpty);
    expect(
      day.map((holiday) => holiday.id),
      contains('obs_kiss_and_make_up'),
    );
    // И всё же ленты в сетке месяца этот день не получает.
    expect(service.holidaysForDate(DateTime(2026, 8, 25)), isEmpty);
  });

  test('russian days carry a title and no invented english name', () {
    for (final holiday in russianDayHolidays) {
      expect(holiday.titleRu, isNotEmpty, reason: holiday.id);
      expect(holiday.titleEn, holiday.titleRu, reason: holiday.id);
      expect(holiday.month, inInclusiveRange(1, 12), reason: holiday.id);
      expect(holiday.day, inInclusiveRange(1, 31), reason: holiday.id);
      expect(holiday.occurrence(2026).isOfficial, isFalse, reason: holiday.id);
    }
  });

  test('no identifier is used twice across the three tables', () {
    final ids = [
      ...fixedHolidays.map((holiday) => holiday.id),
      ...observanceHolidays.map((holiday) => holiday.id),
      ...russianDayHolidays.map((holiday) => holiday.id),
    ];

    expect(ids.toSet().length, ids.length);
  });

}
