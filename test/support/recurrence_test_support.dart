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
  Future<Map<String, DateTime>> memoryDeletions() async =>
      Map.unmodifiable(deletedAtById);
}

/// Ежемесячный повтор с фото в шаблоне и правкой одной даты со своим фото —
/// то, что видит синхронизация, копия и уборка, когда у повтора есть вложения.
({RecurrenceSeries series, RecurrenceOccurrenceException override})
    seriesWithMedia({
  String templateImage = 'image_series.jpg',
  String overrideImage = 'image_override.jpg',
}) {
  final start = DateTime(2099, 1, 9);
  final overrideDate = DateTime(2099, 2, 9);
  final template = MemoryItem(
    id: 'origin',
    type: MemoryType.note,
    title: 'Счётчики',
    body: 'Счётчики',
    memoryDate: start,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    seriesId: 'series',
    repeatRule: RecurrenceFrequency.monthly.name,
    imagePaths: [templateImage],
  );
  final overrideItem = template.copyWith(
    id: 'series_20990209',
    memoryDate: overrideDate,
    isGeneratedOccurrence: true,
    imagePaths: [overrideImage],
  );
  return (
    series: RecurrenceSeries(
      id: 'series',
      frequency: RecurrenceFrequency.monthly,
      template: template,
      startDate: start,
      originItemId: template.id,
      createdAt: template.createdAt,
      updatedAt: template.updatedAt,
    ),
    override: RecurrenceOccurrenceException(
      id: recurrenceExceptionId('series', overrideDate),
      seriesId: 'series',
      occurrenceDate: overrideDate,
      kind: RecurrenceOccurrenceExceptionKind.modified,
      item: overrideItem,
      createdAt: template.createdAt,
      updatedAt: template.updatedAt,
    ),
  );
}
