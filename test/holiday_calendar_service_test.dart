import 'package:ezhednevnik_v2/src/features/calendar/domain/holiday_calendar_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = HolidayCalendarService();

  test('reuses cached holiday lists for the same date', () {
    final first = service.holidaysForDate(DateTime(2026, 5, 9));
    final second = service.holidaysForDate(DateTime(2026, 5, 9, 18));

    expect(identical(first, second), isTrue);
    expect(() => first.clear(), throwsUnsupportedError);
  });

  test('returns fixed Russian holidays offline', () {
    final holidays = service.holidaysForDate(DateTime(2026, 5, 9));

    expect(holidays, hasLength(1));
    expect(holidays.single.titleRu, 'День Победы');
  });

  test('returns multiple holidays on the same date', () {
    final holidays = service.holidaysForDate(DateTime(2026, 4, 12));

    expect(
      holidays.map((holiday) => holiday.id),
      containsAll(<String>['cosmonautics_day', 'orthodox_easter']),
    );
  });

  test('calculates popular movable holidays', () {
    final holidays = service.holidaysForRange(
      DateTime(2026, 10, 1),
      DateTime(2026, 11, 30),
    );

    expect(holidays.any((holiday) => holiday.id == 'fathers_day'), isTrue);
    expect(holidays.any((holiday) => holiday.id == 'mothers_day'), isTrue);
  });

  test('includes Russian military and trade holidays with history', () {
    final airborne = service
        .holidaysForDate(DateTime(2026, 8, 2))
        .firstWhere((holiday) => holiday.id == 'airborne_forces_day');
    final plumber = service
        .holidaysForDate(DateTime(2026, 3, 11))
        .firstWhere((holiday) => holiday.id == 'world_plumbing_day');
    final powerEngineer = service
        .holidaysForDate(DateTime(2026, 12, 22))
        .firstWhere((holiday) => holiday.id == 'power_engineers_day');

    expect(airborne.titleRu, 'День ВДВ');
    expect(airborne.category.name, 'military');
    expect(airborne.descriptionRu, contains('1930'));
    expect(plumber.titleRu, 'Всемирный день сантехника');
    expect(plumber.descriptionRu, contains('2010'));
    expect(powerEngineer.titleRu, contains('электрика'));
    expect(powerEngineer.descriptionRu, contains('ГОЭЛРО'));
  });

  test('calculates the extended Orthodox calendar for 2026', () {
    final expected = <DateTime, String>{
      DateTime(2026, 2, 16): 'maslenitsa',
      DateTime(2026, 2, 22): 'forgiveness_sunday',
      DateTime(2026, 4, 5): 'palm_sunday',
      DateTime(2026, 4, 12): 'orthodox_easter',
      DateTime(2026, 4, 21): 'radonitsa',
      DateTime(2026, 5, 21): 'ascension',
      DateTime(2026, 5, 31): 'trinity',
    };

    for (final entry in expected.entries) {
      expect(
        service.holidaysForDate(entry.key).map((holiday) => holiday.id),
        contains(entry.value),
        reason: '${entry.value} must fall on ${entry.key}',
      );
    }
  });

  test('programmers day follows the 256th day including leap years', () {
    expect(
      service
          .holidaysForDate(DateTime(2026, 9, 13))
          .map((holiday) => holiday.id),
      contains('programmers_day'),
    );
    expect(
      service
          .holidaysForDate(DateTime(2028, 9, 12))
          .map((holiday) => holiday.id),
      contains('programmers_day'),
    );
  });

  test('expanded yearly calendar has unique ids and historical descriptions',
      () {
    final holidays = service.holidaysForRange(
      DateTime(2026, 1, 1),
      DateTime(2026, 12, 31),
    );
    final ids = holidays.map((holiday) => holiday.id).toList();

    expect(holidays.length, greaterThan(65));
    expect(ids.toSet(), hasLength(ids.length));
    for (final holiday in holidays.where(
      (holiday) => holiday.category.name != 'general',
    )) {
      expect(holiday.descriptionRu.length, greaterThan(60));
      expect(holiday.descriptionEn.length, greaterThan(45));
    }
  });
}
