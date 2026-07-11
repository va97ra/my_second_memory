import 'package:flutter_test/flutter_test.dart';
import 'package:ezhednevnik_v2/src/features/calendar/state/calendar_month_data.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_item.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_type.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/domain/shift_schedule.dart';

void main() {
  test('month index handles 5000 records without filtering every cell', () {
    final month = DateTime(2026, 7);
    final items = List.generate(5000, (index) {
      final date = DateTime(2026, 7, index % 31 + 1);
      return MemoryItem(
        id: 'item-$index',
        type: MemoryType.note,
        title: 'Item $index',
        memoryDate: date,
        createdAt: date,
        updatedAt: date,
      );
    });
    final schedule = ShiftSchedule(
      id: 'shift',
      organizationName: 'Work',
      colorValue: 0xFF16A34A,
      startDate: DateTime(2026, 7, 1),
      workDays: 2,
      restDays: 2,
    );

    final data = CalendarMonthData.build(
      month: month,
      items: items,
      shiftSchedules: [schedule],
    );

    expect(data.days.length, anyOf(35, 42));
    expect(
      data.itemsByDay.values.fold<int>(0, (sum, day) => sum + day.length),
      5000,
    );
    expect(data.shiftsByDay, isNotEmpty);
  });
}
