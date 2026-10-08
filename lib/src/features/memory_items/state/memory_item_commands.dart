import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../recurrence/recurrence.dart';
import 'memory_items_controller.dart';

/// Действия над записью из списка.
///
/// Вхождение повтора не лежит в хранилище отдельной строкой: его правка идёт в
/// серию как переопределение. Поэтому каждое действие сначала спрашивает, что
/// перед ним, и только потом выбирает, кому его передать. Решение живёт
/// здесь одно — и для экранов, и для Джарвиса.
class MemoryItemCommands {
  const MemoryItemCommands({
    required MemoryItemsController items,
    required RecurrenceSeriesController series,
  })  : _items = items,
        _series = series;

  final MemoryItemsController _items;
  final RecurrenceSeriesController _series;

  Future<void> toggleDone(MemoryItem item) => item.isGeneratedOccurrence
      ? _series.toggleOccurrenceDone(item)
      : _items.toggleDone(item.id);

  Future<void> archive(MemoryItem item) => item.isGeneratedOccurrence
      ? _series.archiveOccurrence(item)
      : _items.archive(item.id);

  Future<void> restore(MemoryItem item) => item.isGeneratedOccurrence
      ? _series.restoreOccurrence(item)
      : _items.restore(item.id);

  /// Сохраняет правку [edited] записи [original] туда, где запись живёт.
  ///
  /// Перенесённое вхождение адресуется по исходной дате, иначе серия
  /// разъезжается надвое.
  Future<void> save(MemoryItem edited, {required MemoryItem original}) =>
      original.isGeneratedOccurrence
          ? _series.saveOccurrenceOverride(
              edited,
              occurrenceDate: original.memoryDate,
            )
          : _items.update(edited);
}

final memoryItemCommandsProvider = Provider<MemoryItemCommands>((ref) {
  return MemoryItemCommands(
    items: ref.watch(memoryItemsControllerProvider.notifier),
    series: ref.watch(recurrenceSeriesControllerProvider.notifier),
  );
});

void toggleMemoryDone(WidgetRef ref, MemoryItem item) =>
    ref.read(memoryItemCommandsProvider).toggleDone(item);

void archiveMemory(WidgetRef ref, MemoryItem item) =>
    ref.read(memoryItemCommandsProvider).archive(item);

void restoreMemory(WidgetRef ref, MemoryItem item) =>
    ref.read(memoryItemCommandsProvider).restore(item);
