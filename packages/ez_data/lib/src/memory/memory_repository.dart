import 'package:ez_domain/ez_domain.dart';

abstract interface class MemoryRepository {
  Future<List<MemoryItem>> loadAll();

  Future<void> upsert(MemoryItem item);

  Future<void> upsertAll(List<MemoryItem> items);

  Future<void> delete(String id);

  /// Удаляет записи пачкой: слияние убирает их по разнице, а не переписывая
  /// всю таблицу.
  Future<void> deleteAll(List<String> ids);

  Future<void> replaceAll(List<MemoryItem> items);

  Future<void> close();
}
