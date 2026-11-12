import 'package:ezhednevnik_v2/src/features/calendar/state/calendar_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final march = CalendarView(month: DateTime(2026, 3, 17));

  test('месяц держится без дня', () {
    expect(march.month, DateTime(2026, 3));
  });

  test('шаг меняет месяц на странице месяца и год на годовом виде', () {
    expect(march.step(-3).month, DateTime(2025, 12));
    expect(
        march.zoomOut().step(1),
        CalendarView(
          month: DateTime(2027, 3),
          zoom: CalendarZoom.year,
        ));
  });

  test('смахивание вверх и вниз меняет год в любом масштабе', () {
    expect(march.stepYear(1).month, DateTime(2027, 3));
    expect(march.zoomOut().stepYear(-1).year, 2025);
    expect(march.zoomOut().stepYear(-1).showsYear, isTrue);
  });

  test('годовой вид помнит месяц, из которого его открыли', () {
    final year = march.zoomOut();
    expect(year.showsYear, isTrue);
    expect(year.month, DateTime(2026, 3));
    expect(
        year.zoomInto(DateTime(2027, 8)),
        CalendarView(
          month: DateTime(2027, 8),
        ));
  });

  test('щипок меняет масштаб, только сдвинув пальцы на четверть', () {
    expect(march.pinchResult(0.8), isNull);
    expect(march.pinchResult(0.75), CalendarZoom.year);
    expect(march.pinchResult(1.6), isNull);

    final year = march.zoomOut();
    expect(year.pinchResult(1.25), isNull);
    expect(year.pinchResult(1.34), CalendarZoom.month);
    expect(year.pinchResult(0.5), isNull);
  });
}
