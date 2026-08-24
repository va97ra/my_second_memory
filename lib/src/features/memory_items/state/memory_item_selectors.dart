import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ez_domain/ez_domain.dart';
import 'memory_items_controller.dart';
import '../../recurrence/recurrence.dart';

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
        activeReminderDays.add(dateKey(item.remindAt!));
      }
      if (item.isUndated) {
        if (!item.isArchived) undatedNotes.add(item);
        continue;
      }
      byDate
          .putIfAbsent(dateKey(item.memoryDate), () => [])
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
  final occurrenceIndex = RecurrenceOccurrenceIndex(
    series: ref.watch(recurrenceSeriesControllerProvider),
    exceptions: ref.watch(recurrenceExceptionControllerProvider),
  );
  return MemoryItemsIndex.build([
    for (final item in ref.watch(memoryItemsControllerProvider))
      if (!occurrenceIndex.isSkippedPersisted(item)) item,
  ]);
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
      ref.watch(memoryItemsByDateProvider)[dateKey(day)] ?? const [];
  final projected = ref.watch(
    recurrenceItemsForRangeProvider(RecurrenceRange(day, day)),
  );
  return [...persisted, ...projected];
});

Map<int, List<MemoryItem>> indexMemoryItemsByDate(List<MemoryItem> items) {
  return MemoryItemsIndex.build(items).byDate;
}

/// Everything the archive shows. A recurring occurrence is archived by writing
/// an override, not by keeping a row, so the markers have to be read too or
/// archiving one would look like losing it.
List<MemoryItem> archivedMemoryItems({
  required List<MemoryItem> rows,
  required List<RecurrenceSeries> series,
  required List<RecurrenceOccurrenceException> exceptions,
}) {
  final index = RecurrenceOccurrenceIndex(
    series: series,
    exceptions: exceptions,
  );
  final liveSeriesIds = {
    for (final entry in series)
      if (entry.isEnabled) entry.id,
  };
  final result = <String, MemoryItem>{for (final row in rows) row.id: row};
  for (final exception in exceptions) {
    final item = exception.item;
    if (exception.isSkipped ||
        item == null ||
        !item.isArchived ||
        !liveSeriesIds.contains(exception.seriesId) ||
        index.isSuppressedModified(exception)) {
      continue;
    }
    result[item.id] = item;
  }
  return result.values.toList(growable: false);
}

final archivedMemoryItemsProvider = Provider<List<MemoryItem>>((ref) {
  return archivedMemoryItems(
    rows: ref.watch(memoryItemsIndexProvider.select((index) => index.archived)),
    series: ref.watch(recurrenceSeriesControllerProvider),
    exceptions: ref.watch(recurrenceExceptionControllerProvider),
  );
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
    persisted.addAll(itemsByDate[dateKey(day)] ?? const []);
  }
  final projected = ref.watch(
    recurrenceItemsForRangeProvider(
      RecurrenceRange(gridStart, gridEnd.subtract(const Duration(days: 1))),
    ),
  );
  return [...persisted, ...projected];
});

/// Сколько месяцев осталось в сроке подписки у этого вхождения.
///
/// Срок принадлежит серии, поэтому ищется она, а не запись. Для всего, что не
/// подписка с повтором, срока нет.
int? subscriptionTermMonthsFor(
  List<RecurrenceSeries> allSeries,
  MemoryItem item,
) {
  if (item.type != MemoryType.payment ||
      item.paymentCategory != PaymentCategory.subscription.name ||
      item.seriesId == null) {
    return null;
  }
  for (final series in allSeries) {
    if (series.id == item.seriesId) {
      return series.subscriptionTermMonthsFrom(item.memoryDate);
    }
  }
  return null;
}
