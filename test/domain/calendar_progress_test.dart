import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ISO week boundaries belong to the correct week year', () {
    expect(isoWeek(DateTime(2021, 1, 1)), (year: 2020, number: 53));
    expect(isoWeek(DateTime(2021, 1, 4)), (year: 2021, number: 1));
    expect(isoWeek(DateTime(2025, 12, 29)), (year: 2026, number: 1));
    expect(isoWeek(DateTime(2026, 9, 17)), (year: 2026, number: 38));
    expect(isoWeek(DateTime(2027, 1, 3)), (year: 2026, number: 53));
  });
  test(
      'elapsed working days exclude today, include shortened days and transfers',
      () {
    const calendar = ProductionCalendar();
    final september =
        calendar.progress(DateTime(2026, 9), today: DateTime(2026, 9, 17, 23))!;
    expect((september.elapsed, september.total, september.remaining),
        (12, 22, 10));
    final may =
        calendar.progress(DateTime(2026, 5), today: DateTime(2026, 5, 12))!;
    expect(may.elapsed, 5); // 4–8 May; 11 May is a transferred day off.
    expect(
        calendar.progress(DateTime(2026, 9), today: DateTime(2026, 8))!.elapsed,
        0);
    expect(
        calendar
            .progress(DateTime(2026, 9), today: DateTime(2026, 10))!
            .remaining,
        0);
    expect(
        calendar.progress(DateTime(2027, 9), today: DateTime(2027, 9)), isNull);
  });
}
