import 'package:ezhednevnik_v2/src/features/calendar/domain/holiday_calendar_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = HolidayCalendarService();

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
}
