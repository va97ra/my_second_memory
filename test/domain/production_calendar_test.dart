import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calendar = ProductionCalendar();
  test('2026 federal totals and monthly working days', () {
    const expected = [15, 19, 21, 22, 19, 21, 23, 21, 22, 22, 20, 22];
    var hours = 0.0;
    var rest = 0;
    for (var m = 1; m <= 12; m++) {
      final total = calendar.month(DateTime(2026, m))!;
      expect(total.workingDays, expected[m - 1]);
      hours += total.hours(40);
      rest += total.daysOff;
    }
    expect(hours, 1972);
    expect(rest, 118);
  });
  test('transfers, holidays and shortened days are separate', () {
    for (final date in [
      DateTime(2026, 1, 9),
      DateTime(2026, 3, 9),
      DateTime(2026, 5, 11),
      DateTime(2026, 12, 31)
    ]) {
      expect(calendar.day(date), ProductionDay.transferredDayOff);
    }
    expect(calendar.day(DateTime(2026, 3, 8)), ProductionDay.holiday);
    expect(calendar.day(DateTime(2026, 4, 30, 18)), ProductionDay.shortened);
    expect(calendar.day(DateTime(2026, 12, 30)), ProductionDay.working);
    expect(calendar.month(DateTime(2026, 4))!.hours(36), closeTo(157.4, .001));
  });
  test('unsupported years never look like verified calendars', () {
    expect(calendar.day(DateTime(2027, 1, 1)), isNull);
    expect(calendar.month(DateTime(2025, 12)), isNull);
  });
}
