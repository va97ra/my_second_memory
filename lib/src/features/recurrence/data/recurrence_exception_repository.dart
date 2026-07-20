import '../domain/recurrence_occurrence_exception.dart';

abstract interface class RecurrenceExceptionRepository {
  Future<List<RecurrenceOccurrenceException>> loadAll();

  Future<void> upsert(RecurrenceOccurrenceException exception);

  Future<void> upsertAll(List<RecurrenceOccurrenceException> exceptions);

  Future<RecurrenceOccurrenceException> skip(
    String seriesId,
    DateTime occurrenceDate,
  );

  Future<void> delete(String seriesId, DateTime occurrenceDate);

  Future<void> deleteSeries(String seriesId);

  Future<void> replaceAll(List<RecurrenceOccurrenceException> exceptions);

  Future<void> close();
}
