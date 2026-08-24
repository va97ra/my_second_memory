import 'package:ez_domain/ez_domain.dart';

abstract interface class RecurrenceRepository {
  Future<List<RecurrenceSeries>> loadAll();

  Future<void> upsert(RecurrenceSeries series);

  Future<void> upsertAll(List<RecurrenceSeries> series);

  Future<void> delete(String id);

  Future<void> replaceAll(List<RecurrenceSeries> series);

  Future<void> close();
}
