import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/memory_item.dart';
import 'memory_items_controller.dart';
import '../../recurrence/state/recurrence_controller.dart';

class MemoryItemsIndex {
  const MemoryItemsIndex({
    required this.byId,
    required this.byDate,
    required this.archived,
    required this.undatedNotes,
    required this.activeReminderDays,
  });

  factory MemoryItemsIndex.build(List<MemoryItem> items) {
    final byId = <String, MemoryItem>{};
    final byDate = <int, List<MemoryItem>>{};
    final archived = <MemoryItem>[];
    final undatedNotes = <MemoryItem>[];
    final activeReminderDays = <int>{};

    for (final item in items) {
      byId[item.id] = item;
      if (item.isArchived) archived.add(item);
      if (item.remindAt != null && !item.isDone && !item.isArchived) {
        activeReminderDays.add(memoryItemDateKey(item.remindAt!));
      }
      if (item.isUndated) {
        if (!item.isArchived) undatedNotes.add(item);
        continue;
      }
      byDate
          .putIfAbsent(memoryItemDateKey(item.memoryDate), () => [])
          .add(item);
    }

    undatedNotes.sort((left, right) {
      final byUpdated = right.updatedAt.compareTo(left.updatedAt);
      return byUpdated != 0
          ? byUpdated
          : right.createdAt.compareTo(left.createdAt);
    });

    return MemoryItemsIndex(
      byId: Map<String, MemoryItem>.unmodifiable(byId),
      byDate: Map<int, List<MemoryItem>>.unmodifiable({
        for (final entry in byDate.entries)
          entry.key: List<MemoryItem>.unmodifiable(entry.value),
      }),
      archived: List<MemoryItem>.unmodifiable(archived),
      undatedNotes: List<MemoryItem>.unmodifiable(undatedNotes),
      activeReminderDays: Set<int>.unmodifiable(activeReminderDays),
    );
  }

  final Map<String, MemoryItem> byId;
  final Map<int, List<MemoryItem>> byDate;
  final List<MemoryItem> archived;
  final List<MemoryItem> undatedNotes;
  final Set<int> activeReminderDays;
}

final memoryItemsIndexProvider = Provider<MemoryItemsIndex>((ref) {
  return MemoryItemsIndex.build(ref.watch(memoryItemsControllerProvider));
});

final memoryItemByIdProvider = Provider.family<MemoryItem?, String>((ref, id) {
  final persisted = ref.watch(
    memoryItemsIndexProvider.select((index) => index.byId[id]),
  );
  return persisted ?? ref.watch(recurrenceItemByIdProvider(id));
});

final memoryItemsByDateProvider = Provider<Map<int, List<MemoryItem>>>((ref) {
  return ref.watch(memoryItemsIndexProvider.select((index) => index.byDate));
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
  return MemoryItemsIndex.build(items).byDate;
}

int memoryItemDateKey(DateTime date) =>
    date.year * 10000 + date.month * 100 + date.day;

final archivedMemoryItemsProvider = Provider<List<MemoryItem>>((ref) {
  return ref.watch(memoryItemsIndexProvider.select((index) => index.archived));
});

final undatedNotesProvider = Provider<List<MemoryItem>>((ref) {
  return ref.watch(
    memoryItemsIndexProvider.select((index) => index.undatedNotes),
  );
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
