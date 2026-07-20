import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/recurrence_occurrence_exception.dart';
import 'recurrence_exception_repository.dart';

class LocalRecurrenceExceptionRepository
    implements RecurrenceExceptionRepository {
  const LocalRecurrenceExceptionRepository();

  static const storageKey = 'recurrence_occurrence_exceptions_v1';

  @override
  Future<List<RecurrenceOccurrenceException>> loadAll() async {
    final raw = (await SharedPreferences.getInstance()).getString(storageKey);
    if (raw == null || raw.isEmpty) return const [];
    return (jsonDecode(raw) as List<dynamic>).map((entry) {
      return RecurrenceOccurrenceException.fromJson(
        Map<String, Object?>.from(entry as Map),
      );
    }).toList();
  }

  @override
  Future<void> upsert(RecurrenceOccurrenceException exception) async {
    final all = {for (final item in await loadAll()) item.id: item};
    all[exception.id] = exception;
    await replaceAll(all.values.toList());
  }

  @override
  Future<void> upsertAll(
    List<RecurrenceOccurrenceException> exceptions,
  ) async {
    if (exceptions.isEmpty) return;
    final all = {for (final item in await loadAll()) item.id: item};
    for (final exception in exceptions) {
      all[exception.id] = exception;
    }
    await replaceAll(all.values.toList());
  }

  @override
  Future<RecurrenceOccurrenceException> skip(
    String seriesId,
    DateTime occurrenceDate,
  ) async {
    final now = DateTime.now();
    final date = DateTime(
      occurrenceDate.year,
      occurrenceDate.month,
      occurrenceDate.day,
    );
    final exception = RecurrenceOccurrenceException(
      id: recurrenceExceptionId(seriesId, date),
      seriesId: seriesId,
      occurrenceDate: date,
      kind: RecurrenceOccurrenceExceptionKind.skipped,
      createdAt: now,
      updatedAt: now,
    );
    await upsert(exception);
    return exception;
  }

  @override
  Future<void> delete(String seriesId, DateTime occurrenceDate) async {
    final id = recurrenceExceptionId(seriesId, occurrenceDate);
    await replaceAll([
      for (final item in await loadAll())
        if (item.id != id) item,
    ]);
  }

  @override
  Future<void> deleteSeries(String seriesId) async {
    await replaceAll([
      for (final item in await loadAll())
        if (item.seriesId != seriesId) item,
    ]);
  }

  @override
  Future<void> replaceAll(
    List<RecurrenceOccurrenceException> exceptions,
  ) async {
    await (await SharedPreferences.getInstance()).setString(
      storageKey,
      jsonEncode(exceptions.map((item) => item.toJson()).toList()),
    );
  }

  @override
  Future<void> close() async {}
}
