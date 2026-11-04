import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../recurrence/recurrence.dart';
import 'memory_item_selectors.dart';
import 'memory_items_controller.dart';

/// Действия над записью из списка.
///
/// Вхождение повтора не лежит в хранилище отдельной строкой: его правка идёт в
/// серию как переопределение. Поэтому каждое действие сначала спрашивает, что
/// перед ним, и только потом выбирает, кому его передать.
void toggleMemoryDone(WidgetRef ref, MemoryItem item) {
  if (item.isGeneratedOccurrence) {
    ref
        .read(recurrenceSeriesControllerProvider.notifier)
        .toggleOccurrenceDone(item);
    return;
  }
  ref.read(memoryItemsControllerProvider.notifier).toggleDone(item.id);
}

void archiveMemory(WidgetRef ref, MemoryItem item) {
  if (item.isGeneratedOccurrence) {
    ref
        .read(recurrenceSeriesControllerProvider.notifier)
        .archiveOccurrence(item);
    return;
  }
  ref.read(memoryItemsControllerProvider.notifier).archive(item.id);
}

void restoreMemory(WidgetRef ref, MemoryItem item) {
  if (item.isGeneratedOccurrence) {
    ref
        .read(recurrenceSeriesControllerProvider.notifier)
        .restoreOccurrence(item);
    return;
  }
  ref.read(memoryItemsControllerProvider.notifier).restore(item.id);
}

/// Что удалять у записи серии: её одну, её и дальше или всю серию.
enum MemoryDeleteScope { one, future, series }

Future<void> deleteMemory(
  WidgetRef ref,
  MemoryItem item,
  MemoryDeleteScope scope,
) {
  final series = ref.read(recurrenceSeriesControllerProvider.notifier);
  final seriesId = item.seriesId;
  if (seriesId == null) {
    return ref.read(memoryItemsControllerProvider.notifier).delete(item.id);
  }
  return switch (scope) {
    MemoryDeleteScope.series => series.deleteSeries(seriesId),
    MemoryDeleteScope.future =>
      series.deleteFromDate(seriesId, item.memoryDate, occurrence: item),
    MemoryDeleteScope.one => series.deleteOccurrence(item),
  };
}

/// Сохраняет правку туда, где запись живёт. Вхождение повтора адресуется по
/// исходной дате, иначе серия разъезжается надвое.
Future<void> saveMemoryEdit(
  WidgetRef ref,
  MemoryItem edited, {
  required MemoryItem original,
}) {
  if (original.isGeneratedOccurrence) {
    return ref
        .read(recurrenceSeriesControllerProvider.notifier)
        .saveOccurrenceOverride(edited, occurrenceDate: original.memoryDate);
  }
  return ref.read(memoryItemsControllerProvider.notifier).update(edited);
}

/// Переносит запись на другой день вместе с напоминанием.
Future<void> moveMemoryToDay(WidgetRef ref, MemoryItem item, DateTime day) async {
  final date = DateTime(day.year, day.month, day.day);
  if (isSameDay(item.memoryDate, date)) return;
  final remindAt = reminderAfterMove(item.remindAt, item.timeMinutes, date);
  await saveMemoryEdit(
    ref,
    item.copyWith(
      memoryDate: date,
      remindAt: remindAt,
      clearReminder: remindAt == null,
    ),
    original: item,
  );
}

/// Листок бросили на другой листок. Другой день — запись переезжает на него.
/// Тот же день — встаёт перед ним, но только среди записей без времени: записи
/// со временем стоят по часам, и порядок им задаёт время.
Future<void> dropMemoryOn(
  WidgetRef ref,
  MemoryItem moved,
  MemoryItem target,
) async {
  if (moved.id == target.id) return;
  if (!isSameDay(moved.memoryDate, target.memoryDate)) {
    return moveMemoryToDay(ref, moved, target.memoryDate);
  }
  bool reorderable(MemoryItem item) =>
      item.timeMinutes == null && !item.isGeneratedOccurrence;
  if (!reorderable(moved) ||
      !reorderable(target) ||
      moved.isDone != target.isDone) {
    return;
  }

  final day = ref
      .read(memoryItemsForDayProvider(target.memoryDate))
      .where((item) =>
          reorderable(item) && !item.isArchived && item.isDone == moved.isDone)
      .toList()
    ..sort((a, b) {
      final byPriority = b.priority.compareTo(a.priority);
      return byPriority != 0 ? byPriority : a.createdAt.compareTo(b.createdAt);
    });
  day.removeWhere((item) => item.id == moved.id);
  day.insert(day.indexWhere((item) => item.id == target.id), moved);
  final items = ref.read(memoryItemsControllerProvider.notifier);
  for (var index = 0; index < day.length; index++) {
    final priority = day.length - index;
    if (day[index].priority != priority) {
      await items.update(day[index].copyWith(priority: priority));
    }
  }
}
