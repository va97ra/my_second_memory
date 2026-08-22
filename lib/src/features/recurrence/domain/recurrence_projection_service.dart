import '../../memory_items/domain/memory_item.dart';
import '../../memory_items/domain/memory_status.dart';
import 'recurrence_occurrence_exception.dart';
import 'recurrence_series.dart';

class RecurrenceProjectionService {
  const RecurrenceProjectionService();

  List<MemoryItem> itemsForRange({
    required DateTime start,
    required DateTime end,
    required List<RecurrenceSeries> series,
    required List<RecurrenceOccurrenceException> exceptions,
    required List<MemoryItem> persistedItems,
  }) {
    final rangeStart = dateOnly(start);
    final rangeEnd = dateOnly(end);
    final occurrenceIndex = RecurrenceOccurrenceIndex(
      series: series,
      exceptions: exceptions,
    );
    final enabledSeries = [
      for (final entry in series)
        if (entry.isEnabled) entry,
    ];
    if (enabledSeries.isEmpty) return const [];

    final persistedKeys = <String>{
      for (final item in persistedItems)
        if (item.seriesId != null)
          occurrenceKey(item.seriesId!, item.memoryDate),
    };
    final persistedIds = <String>{
      for (final item in persistedItems) item.id,
    };
    final exceptionsByKey = {
      for (final exception in exceptions)
        occurrenceKey(exception.seriesId, exception.occurrenceDate): exception,
    };
    final result = <MemoryItem>[];
    final enabledSeriesIds = <String>{};
    for (final entry in enabledSeries) {
      enabledSeriesIds.add(entry.id);
      for (final date in recurrenceDatesInRange(entry, rangeStart, rangeEnd)) {
        final key = occurrenceKey(entry.id, date);
        if (persistedKeys.contains(key)) continue;
        final exception = exceptionsByKey[key];
        if (exception?.isSkipped == true) continue;
        if (exception == null) {
          result.add(occurrenceFromSeries(entry, date));
        }
      }
    }
    for (final exception in exceptions) {
      final item = exception.item;
      if (exception.isSkipped ||
          item == null ||
          occurrenceIndex.isSuppressedModified(exception) ||
          !enabledSeriesIds.contains(exception.seriesId) ||
          item.memoryDate.isBefore(rangeStart) ||
          item.memoryDate.isAfter(rangeEnd) ||
          persistedIds.contains(item.id)) {
        continue;
      }
      result.add(item);
    }
    result.sort(compareOccurrences);
    return result;
  }

  MemoryItem? itemById({
    required String id,
    required List<RecurrenceSeries> series,
    required List<RecurrenceOccurrenceException> exceptions,
    required List<MemoryItem> persistedItems,
  }) {
    final occurrenceIndex = RecurrenceOccurrenceIndex(
      series: series,
      exceptions: exceptions,
    );
    for (final item in persistedItems) {
      if (item.id != id) continue;
      return occurrenceIndex.isSkippedPersisted(item) ? null : item;
    }
    for (final exception in exceptions) {
      if (exception.item?.id == id &&
          !exception.isSkipped &&
          !occurrenceIndex.isSuppressedModified(exception)) {
        return exception.item;
      }
    }
    for (final entry in series) {
      final date = occurrenceDateFromId(entry.id, id);
      if (date == null || !isOccurrenceDate(entry, date)) continue;
      final key = occurrenceKey(entry.id, date);
      for (final exception in exceptions) {
        if (occurrenceKey(exception.seriesId, exception.occurrenceDate) !=
            key) {
          continue;
        }
        if (exception.isSkipped) return null;
        return exception.item;
      }
      return entry.isEnabled ? occurrenceFromSeries(entry, date) : null;
    }
    return null;
  }
}

/// Resolves every stored representation back to the source occurrence. This
/// keeps a canonical skip authoritative even when an old device uploads a
/// persisted row or a modified marker under the moved date.
class RecurrenceOccurrenceIndex {
  RecurrenceOccurrenceIndex({
    required List<RecurrenceSeries> series,
    required List<RecurrenceOccurrenceException> exceptions,
  })  : _seriesById = {for (final entry in series) entry.id: entry},
        _exceptionsByKey = _newestExceptionsByKey(exceptions),
        _sourceDateByItemId = _newestSourceDatesByItemId(exceptions);

  final Map<String, RecurrenceSeries> _seriesById;
  final Map<String, RecurrenceOccurrenceException> _exceptionsByKey;
  final Map<String, DateTime> _sourceDateByItemId;

  DateTime sourceDateFor(MemoryItem item, {DateTime? fallback}) {
    final seriesId = item.seriesId;
    if (seriesId == null) return dateOnly(fallback ?? item.memoryDate);
    final entry = _seriesById[seriesId];
    if (entry?.originItemId == item.id) return dateOnly(entry!.startDate);
    final encoded = occurrenceDateFromId(seriesId, item.id);
    if (encoded != null) return dateOnly(encoded);
    return dateOnly(
      _sourceDateByItemId[item.id] ?? fallback ?? item.memoryDate,
    );
  }

  bool isSkippedPersisted(MemoryItem item) {
    final seriesId = item.seriesId;
    if (seriesId == null) return false;
    final sourceDate = sourceDateFor(item);
    final exception = _exceptionsByKey[occurrenceKey(seriesId, sourceDate)];
    if (exception?.isSkipped != true) return false;
    if (item.updatedAt.isAfter(exception!.updatedAt)) return false;
    // Older versions represented a moved, persisted occurrence as
    // item(source id, moved date) + null skip(source). Keep that valid shape.
    // New deletion markers carry the deleted item id and are unambiguous.
    return dateKey(item.memoryDate) == dateKey(sourceDate) ||
        exception.item?.id == item.id;
  }

  bool isSuppressedModified(RecurrenceOccurrenceException exception) {
    final item = exception.item;
    if (exception.isSkipped || item == null) return false;
    final sourceDate = sourceDateFor(
      item,
      fallback: exception.occurrenceDate,
    );
    final canonical =
        _exceptionsByKey[occurrenceKey(exception.seriesId, sourceDate)];
    if (canonical?.isSkipped == true &&
        !exception.updatedAt.isAfter(canonical!.updatedAt)) {
      return true;
    }
    final endDate = _seriesById[exception.seriesId]?.effectiveEndDate;
    return endDate != null &&
        (sourceDate.isAfter(dateOnly(endDate)) ||
            item.memoryDate.isAfter(dateOnly(endDate)));
  }

  static Map<String, RecurrenceOccurrenceException> _newestExceptionsByKey(
    List<RecurrenceOccurrenceException> exceptions,
  ) {
    final result = <String, RecurrenceOccurrenceException>{};
    for (final exception in exceptions) {
      final key = occurrenceKey(exception.seriesId, exception.occurrenceDate);
      final existing = result[key];
      if (existing == null || exception.updatedAt.isAfter(existing.updatedAt)) {
        result[key] = exception;
      }
    }
    return result;
  }

  static Map<String, DateTime> _newestSourceDatesByItemId(
    List<RecurrenceOccurrenceException> exceptions,
  ) {
    final result = <String, DateTime>{};
    final timestamps = <String, DateTime>{};
    for (final exception in exceptions) {
      final itemId = exception.item?.id;
      if (itemId == null) continue;
      final previous = timestamps[itemId];
      if (previous == null || exception.updatedAt.isAfter(previous)) {
        result[itemId] = dateOnly(exception.occurrenceDate);
        timestamps[itemId] = exception.updatedAt;
      }
    }
    return result;
  }
}

List<DateTime> recurrenceDatesInRange(
  RecurrenceSeries series,
  DateTime start,
  DateTime end,
) {
  final anchor = dateOnly(series.startDate);
  final rangeStart = latestDate(dateOnly(start), anchor);
  final effectiveEnd = series.effectiveEndDate;
  final seriesEnd = effectiveEnd == null ? null : dateOnly(effectiveEnd);
  final rangeEnd = seriesEnd == null
      ? dateOnly(end)
      : earliestDate(dateOnly(end), seriesEnd);
  if (rangeEnd.isBefore(rangeStart)) return const [];

  final dates = <DateTime>[];
  switch (series.frequency) {
    case RecurrenceFrequency.monthly:
      var monthIndex = (rangeStart.year - anchor.year) * 12 +
          rangeStart.month -
          anchor.month;
      if (monthIndex < 0) monthIndex = 0;
      for (;; monthIndex++) {
        final month = DateTime(anchor.year, anchor.month + monthIndex);
        final date = safeDate(month.year, month.month, anchor.day);
        if (date.isAfter(rangeEnd)) break;
        if (!date.isBefore(rangeStart)) dates.add(date);
      }
    case RecurrenceFrequency.yearly:
      var year = rangeStart.year;
      if (year < anchor.year) year = anchor.year;
      for (; year <= rangeEnd.year; year++) {
        final date = safeDate(year, anchor.month, anchor.day);
        if (!date.isBefore(rangeStart) && !date.isAfter(rangeEnd)) {
          dates.add(date);
        }
      }
  }
  return dates;
}

bool isOccurrenceDate(RecurrenceSeries series, DateTime date) {
  final normalized = dateOnly(date);
  return recurrenceDatesInRange(series, normalized, normalized).isNotEmpty;
}

MemoryItem occurrenceFromSeries(RecurrenceSeries series, DateTime date) {
  final template = series.template;
  final normalized = dateOnly(date);
  final reminder = shiftedReminder(template, normalized);
  return template.copyWith(
    id: occurrenceId(series.id, normalized),
    memoryDate: normalized,
    status: MemoryStatus.active,
    remindAt: reminder,
    clearReminder: reminder == null,
    seriesId: series.id,
    repeatRule: series.frequency.name,
    isGeneratedOccurrence: true,
  );
}

DateTime? shiftedReminder(MemoryItem template, DateTime date) {
  final source = template.remindAt;
  if (source == null) return null;
  final eventMinutes = template.timeMinutes ?? 9 * 60;
  final sourceEvent = DateTime(
    template.memoryDate.year,
    template.memoryDate.month,
    template.memoryDate.day,
    eventMinutes ~/ 60,
    eventMinutes % 60,
  );
  final offset = sourceEvent.difference(source);
  return DateTime(
    date.year,
    date.month,
    date.day,
    eventMinutes ~/ 60,
    eventMinutes % 60,
  ).subtract(offset);
}

String occurrenceId(String seriesId, DateTime date) =>
    '${seriesId}_${dateKey(date)}';

String occurrenceKey(String seriesId, DateTime date) =>
    '$seriesId:${dateKey(date)}';

DateTime? occurrenceDateFromId(String seriesId, String id) {
  final prefix = '${seriesId}_';
  if (!id.startsWith(prefix)) return null;
  final raw = id.substring(prefix.length);
  if (raw.length != 8) return null;
  final value = int.tryParse(raw);
  if (value == null) return null;
  final year = value ~/ 10000;
  final month = (value ~/ 100) % 100;
  final day = value % 100;
  final date = DateTime(year, month, day);
  return date.year == year && date.month == month && date.day == day
      ? date
      : null;
}

int compareOccurrences(MemoryItem left, MemoryItem right) {
  final byDate = left.memoryDate.compareTo(right.memoryDate);
  if (byDate != 0) return byDate;
  return (left.timeMinutes ?? 24 * 60).compareTo(right.timeMinutes ?? 24 * 60);
}

DateTime safeDate(int year, int month, int day) {
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, day > lastDay ? lastDay : day);
}

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

int dateKey(DateTime value) =>
    value.year * 10000 + value.month * 100 + value.day;

DateTime latestDate(DateTime left, DateTime right) =>
    left.isAfter(right) ? left : right;

DateTime earliestDate(DateTime left, DateTime right) =>
    left.isBefore(right) ? left : right;
