import '../memory/memory_item.dart';
import 'recurrence_dates.dart';
import 'recurrence_occurrence_exception.dart';
import 'recurrence_projection_service.dart';
import 'recurrence_series.dart';

/// Проекция повторов, посчитанная один раз для текущих данных.
///
/// Ячейка месяца, день, лента и напоминания спрашивают вхождения на свой
/// диапазон. Раньше каждый такой вопрос заново строил множества по всем
/// записям, сериям и исключениям — 42 ячейки месяца давали 42 прохода по
/// всему дневнику. Теперь они строятся здесь, когда меняются данные, а вопрос
/// о диапазоне перебирает только даты серий и правки отдельных дат.
final class RecurrenceProjection {
  RecurrenceProjection({
    required List<RecurrenceSeries> series,
    required List<RecurrenceOccurrenceException> exceptions,
    required List<MemoryItem> persistedItems,
  })  : occurrenceIndex = RecurrenceOccurrenceIndex(
          series: series,
          exceptions: exceptions,
        ),
        _series = series {
    for (final entry in series) {
      if (entry.isEnabled) _enabledSeries.add(entry);
    }
    for (final item in persistedItems) {
      _persistedById.putIfAbsent(item.id, () => item);
      if (item.seriesId != null) {
        _persistedKeys.add(occurrenceKey(item.seriesId!, item.memoryDate));
      }
    }
    final enabledIds = {for (final entry in _enabledSeries) entry.id};
    for (final exception in exceptions) {
      final key = occurrenceKey(exception.seriesId, exception.occurrenceDate);
      _exceptionsByKey[key] = exception;
      _firstExceptionByKey.putIfAbsent(key, () => exception);
      final item = exception.item;
      if (item == null || exception.isSkipped) continue;
      if (!occurrenceIndex.isSuppressedModified(exception)) {
        _visibleOverrideByItemId.putIfAbsent(item.id, () => item);
        if (enabledIds.contains(exception.seriesId) &&
            !_persistedById.containsKey(item.id)) {
          _projectedOverrides.add(item);
        }
      }
    }
  }

  /// Разрешение любого представления вхождения к исходной дате.
  final RecurrenceOccurrenceIndex occurrenceIndex;

  final List<RecurrenceSeries> _series;
  final _enabledSeries = <RecurrenceSeries>[];
  final _persistedById = <String, MemoryItem>{};
  final _persistedKeys = <String>{};
  final _exceptionsByKey = <String, RecurrenceOccurrenceException>{};
  final _firstExceptionByKey = <String, RecurrenceOccurrenceException>{};
  final _visibleOverrideByItemId = <String, MemoryItem>{};
  final _projectedOverrides = <MemoryItem>[];

  /// Вхождения повторов с [start] по [end] включительно.
  List<MemoryItem> itemsForRange(DateTime start, DateTime end) {
    if (_enabledSeries.isEmpty) return const [];
    final rangeStart = dateOnly(start);
    final rangeEnd = dateOnly(end);
    final result = <MemoryItem>[];
    for (final entry in _enabledSeries) {
      for (final date in recurrenceDatesInRange(entry, rangeStart, rangeEnd)) {
        final key = occurrenceKey(entry.id, date);
        if (_persistedKeys.contains(key)) continue;
        if (_exceptionsByKey.containsKey(key)) continue;
        result.add(occurrenceFromSeries(entry, date));
      }
    }
    for (final item in _projectedOverrides) {
      if (item.memoryDate.isBefore(rangeStart) ||
          item.memoryDate.isAfter(rangeEnd)) {
        continue;
      }
      result.add(item);
    }
    result.sort(compareOccurrences);
    return result;
  }

  /// Запись или вхождение повтора по id, как его видит человек; null —
  /// такого нет или оно удалено.
  MemoryItem? itemById(String id) {
    final persisted = _persistedById[id];
    if (persisted != null) {
      return occurrenceIndex.isSkippedPersisted(persisted) ? null : persisted;
    }
    final override = _visibleOverrideByItemId[id];
    if (override != null) return override;
    for (final entry in _series) {
      final date = entry.originItemId == id
          ? dateOnly(entry.startDate)
          : occurrenceDateFromId(entry.id, id);
      if (date == null || !isOccurrenceDate(entry, date)) continue;
      final exception = _firstExceptionByKey[occurrenceKey(entry.id, date)];
      if (exception != null) {
        return exception.isSkipped ? null : exception.item;
      }
      return entry.isEnabled ? occurrenceFromSeries(entry, date) : null;
    }
    return null;
  }
}
