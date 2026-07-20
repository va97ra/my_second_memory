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
    final persistedKeys = <String>{
      for (final item in persistedItems)
        if (item.seriesId != null)
          occurrenceKey(item.seriesId!, item.memoryDate),
    };
    final exceptionsByKey = {
      for (final exception in exceptions)
        occurrenceKey(exception.seriesId, exception.occurrenceDate): exception,
    };
    final result = <MemoryItem>[];
    final enabledSeriesIds = <String>{};
    for (final entry in series) {
      if (!entry.isEnabled) continue;
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
          !enabledSeriesIds.contains(exception.seriesId) ||
          item.memoryDate.isBefore(rangeStart) ||
          item.memoryDate.isAfter(rangeEnd) ||
          persistedItems.any((entry) => entry.id == item.id)) {
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
    for (final item in persistedItems) {
      if (item.id == id) return item;
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
        return exception.isSkipped ? null : exception.item;
      }
      return entry.isEnabled ? occurrenceFromSeries(entry, date) : null;
    }
    return null;
  }
}

List<DateTime> recurrenceDatesInRange(
  RecurrenceSeries series,
  DateTime start,
  DateTime end,
) {
  final anchor = dateOnly(series.startDate);
  final rangeStart = latestDate(dateOnly(start), anchor);
  final seriesEnd = series.endDate == null ? null : dateOnly(series.endDate!);
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
