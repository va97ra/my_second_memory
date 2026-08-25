import 'dart:convert';

import 'package:ez_domain/ez_domain.dart';

/// Общее для тестов повторов: запись состояния в хранилище и наблюдатель,
/// запоминающий удаления.
String encodeItems(List<MemoryItem> items) =>
    jsonEncode(items.map((item) => item.toJson()).toList());

String encodeSeries(List<RecurrenceSeries> series) =>
    jsonEncode(series.map((item) => item.toJson()).toList());

String encodeExceptions(List<RecurrenceOccurrenceException> exceptions) =>
    jsonEncode(exceptions.map((item) => item.toJson()).toList());

class DeletionObserver extends NoopSyncMutationObserver {
  DeletionObserver(this.deletedAtById);

  final Map<String, DateTime> deletedAtById;

  @override
  Future<void> memoryDeleted(String id, DateTime deletedAt) async {
    deletedAtById[id] = deletedAt;
  }

  @override
  Future<DateTime?> memoryDeletedAt(String id) async => deletedAtById[id];

  @override
  Future<Map<String, DateTime>> memoryDeletions() async =>
      Map.unmodifiable(deletedAtById);
}
