import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/memory_item.dart';
import 'memory_items_controller.dart';
import '../../recurrence/state/recurrence_controller.dart';

final memoryItemByIdProvider = Provider.family<MemoryItem?, String>((ref, id) {
  final persisted = ref.watch(
    memoryItemsControllerProvider.select((items) {
      for (final item in items) {
        if (item.id == id) return item;
      }
      return null;
    }),
  );
  return persisted ?? ref.watch(recurrenceItemByIdProvider(id));
});

final memoryItemsForDayProvider =
    Provider.family<List<MemoryItem>, DateTime>((ref, date) {
  final day = DateTime(date.year, date.month, date.day);
  final persisted = ref.watch(memoryItemsControllerProvider).where((item) {
    final itemDate = item.memoryDate;
    return itemDate.year == day.year &&
        itemDate.month == day.month &&
        itemDate.day == day.day;
  }).toList(growable: false);
  final projected = ref.watch(
    recurrenceItemsForRangeProvider(RecurrenceRange(day, day)),
  );
  return [...persisted, ...projected];
});

final archivedMemoryItemsProvider = Provider<List<MemoryItem>>((ref) {
  return ref
      .watch(memoryItemsControllerProvider)
      .where((item) => item.isArchived)
      .toList(growable: false);
});

final visibleCalendarItemsProvider =
    Provider.family<List<MemoryItem>, DateTime>((ref, month) {
  final firstOfMonth = DateTime(month.year, month.month);
  final gridStart = firstOfMonth.subtract(
    Duration(days: firstOfMonth.weekday - DateTime.monday),
  );
  final gridEnd = gridStart.add(const Duration(days: 42));
  final persisted = ref.watch(memoryItemsControllerProvider).where((item) {
    final date = item.memoryDate;
    return !date.isBefore(gridStart) && date.isBefore(gridEnd);
  }).toList(growable: false);
  final projected = ref.watch(
    recurrenceItemsForRangeProvider(
      RecurrenceRange(gridStart, gridEnd.subtract(const Duration(days: 1))),
    ),
  );
  return [...persisted, ...projected];
});
