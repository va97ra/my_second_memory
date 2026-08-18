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

final memoryItemsByDateProvider = Provider<Map<int, List<MemoryItem>>>((ref) {
  return indexMemoryItemsByDate(ref.watch(memoryItemsControllerProvider));
});

final memoryItemsForDayProvider =
    Provider.family<List<MemoryItem>, DateTime>((ref, date) {
  final day = DateTime(date.year, date.month, date.day);
  final persisted =
      ref.watch(memoryItemsByDateProvider)[memoryItemDateKey(day)] ?? const [];
  final projected = ref.watch(
    recurrenceItemsForRangeProvider(RecurrenceRange(day, day)),
  );
  return [...persisted, ...projected];
});

Map<int, List<MemoryItem>> indexMemoryItemsByDate(List<MemoryItem> items) {
  final result = <int, List<MemoryItem>>{};
  for (final item in items) {
    if (item.isUndated) continue;
    result.putIfAbsent(memoryItemDateKey(item.memoryDate), () => []).add(item);
  }
  return Map<int, List<MemoryItem>>.unmodifiable({
    for (final entry in result.entries)
      entry.key: List<MemoryItem>.unmodifiable(entry.value),
  });
}

int memoryItemDateKey(DateTime date) =>
    date.year * 10000 + date.month * 100 + date.day;

final archivedMemoryItemsProvider = Provider<List<MemoryItem>>((ref) {
  return ref
      .watch(memoryItemsControllerProvider)
      .where((item) => item.isArchived)
      .toList(growable: false);
});

final undatedNotesProvider = Provider<List<MemoryItem>>((ref) {
  final notes = ref
      .watch(memoryItemsControllerProvider)
      .where((item) => item.isUndated && !item.isArchived)
      .toList(growable: false);
  return [...notes]..sort((left, right) {
      final byUpdated = right.updatedAt.compareTo(left.updatedAt);
      return byUpdated != 0
          ? byUpdated
          : right.createdAt.compareTo(left.createdAt);
    });
});

final visibleCalendarItemsProvider =
    Provider.family<List<MemoryItem>, DateTime>((ref, month) {
  final firstOfMonth = DateTime(month.year, month.month);
  final gridStart = firstOfMonth.subtract(
    Duration(days: firstOfMonth.weekday - DateTime.monday),
  );
  final gridEnd = gridStart.add(const Duration(days: 42));
  final itemsByDate = ref.watch(memoryItemsByDateProvider);
  final persisted = <MemoryItem>[];
  for (var day = gridStart;
      day.isBefore(gridEnd);
      day = day.add(const Duration(days: 1))) {
    persisted.addAll(itemsByDate[memoryItemDateKey(day)] ?? const []);
  }
  final projected = ref.watch(
    recurrenceItemsForRangeProvider(
      RecurrenceRange(gridStart, gridEnd.subtract(const Duration(days: 1))),
    ),
  );
  return [...persisted, ...projected];
});
