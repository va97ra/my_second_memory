import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/calendar/ui/widgets/calendar_day_cell_body.dart';
import 'package:ezhednevnik_v2/src/features/calendar/ui/widgets/calendar_day_cell_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

MemoryItem _item(String id, {int? timeMinutes, DateTime? createdAt}) {
  final date = DateTime(2026, 5, 20);
  return MemoryItem(
    id: id,
    type: MemoryType.task,
    title: id,
    body: id,
    memoryDate: date,
    createdAt: createdAt ?? date,
    updatedAt: date,
    timeMinutes: timeMinutes,
  );
}

List<MemoryItem> _items(int count) =>
    [for (var i = 0; i < count; i++) _item('item-$i')];

void main() {
  _cellFitsAtAnyTextScale();

  test('a tall cell shows every record it has', () {
    final layout = CalendarDayCellLayout.forCell(
      height: 120,
      items: _items(3),
      hasHoliday: false,
    );

    expect(layout.visibleItems, hasLength(3));
    expect(layout.showsOverflow, isFalse);
  });

  test('records that do not fit are counted, not silently dropped', () {
    // 30 на шапку и по 12 на строку: здесь помещается три строки.
    final layout = CalendarDayCellLayout.forCell(
      height: 30 + 12 * 3,
      items: _items(10),
      hasHoliday: false,
    );

    // Одна строка уходит под счётчик, иначе о спрятанном никто не узнает.
    expect(layout.visibleItems, hasLength(2));
    expect(layout.overflowCount, 8);
    expect(layout.visibleItems.length + layout.overflowCount, 10);
  });

  test('a holiday takes a row from the records', () {
    final withoutHoliday = CalendarDayCellLayout.forCell(
      height: 30 + 12 * 3,
      items: _items(3),
      hasHoliday: false,
    );
    final withHoliday = CalendarDayCellLayout.forCell(
      height: 30 + 12 * 3,
      items: _items(3),
      hasHoliday: true,
    );

    expect(withoutHoliday.visibleItems, hasLength(3));
    expect(withHoliday.showsHoliday, isTrue);
    expect(withHoliday.visibleItems.length, lessThan(3));
  });

  test('a cell too short for content shows none of it', () {
    final layout = CalendarDayCellLayout.forCell(
      height: 24,
      items: _items(5),
      hasHoliday: true,
    );

    expect(layout.showsEvents, isFalse);
    expect(layout.visibleItems, isEmpty);
    expect(layout.showsHoliday, isFalse);
    // Ничего не влезло — значит спрятано всё, и счётчик это признаёт.
    expect(layout.overflowCount, 5);
  });

  test('a very tall cell still stops at nine rows', () {
    final layout = CalendarDayCellLayout.forCell(
      height: 1000,
      items: _items(20),
      hasHoliday: false,
    );

    expect(layout.visibleItems.length, lessThanOrEqualTo(9));
    expect(layout.showsOverflow, isTrue);
  });

  test('timed records come first, in order of the day', () {
    final sorted = sortedDayItems([
      _item('untimed', createdAt: DateTime(2026, 5, 1)),
      _item('evening', timeMinutes: 20 * 60),
      _item('morning', timeMinutes: 8 * 60),
    ]);

    expect(sorted.map((item) => item.id), ['morning', 'evening', 'untimed']);
  });

  test('records without a time keep the order they were created in', () {
    final sorted = sortedDayItems([
      _item('second', createdAt: DateTime(2026, 5, 2)),
      _item('first', createdAt: DateTime(2026, 5, 1)),
    ]);

    expect(sorted.map((item) => item.id), ['first', 'second']);
  });
}

/// Ячейка рисуется ровно тем, что насчитал [CalendarDayCellLayout]: при
/// любом шрифте системы содержимое не вылезает за её низ.
void _cellFitsAtAnyTextScale() {
  testWidgets('записи в ячейке не вылезают за край при крупном шрифте',
      (tester) async {
    for (final scale in const [1.0, 1.3, 2.0]) {
      for (var count = 1; count <= 4; count++) {
        for (var height = 40.0; height <= 120; height += 3.7) {
          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Center(
                  child: SizedBox(
                    width: 92,
                    height: height,
                    child: CalendarDayCellBody(
                      date: DateTime(2026, 5, 20),
                      locale: 'ru',
                      isInVisibleMonth: true,
                      isToday: true,
                      items: _items(count),
                      shiftSchedules: const [],
                      holidays: const [],
                      hasAlarm: false,
                      foreground: Colors.black,
                      todayColor: Colors.red,
                    ),
                  ),
                ),
              ),
            ),
          );
          expect(
            tester.takeException(),
            isNull,
            reason: 'шрифт $scale, записей $count, высота $height',
          );
        }
      }
    }
  });
}
