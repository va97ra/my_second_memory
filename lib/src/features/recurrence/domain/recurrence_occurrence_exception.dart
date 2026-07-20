import '../../memory_items/domain/memory_item.dart';

enum RecurrenceOccurrenceExceptionKind { modified, skipped }

class RecurrenceOccurrenceException {
  const RecurrenceOccurrenceException({
    required this.id,
    required this.seriesId,
    required this.occurrenceDate,
    required this.kind,
    required this.createdAt,
    required this.updatedAt,
    this.item,
  });

  final String id;
  final String seriesId;
  final DateTime occurrenceDate;
  final RecurrenceOccurrenceExceptionKind kind;
  final MemoryItem? item;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isSkipped => kind == RecurrenceOccurrenceExceptionKind.skipped;

  Map<String, Object?> toJson() => {
        'id': id,
        'seriesId': seriesId,
        'occurrenceDate': occurrenceDate.toIso8601String(),
        'kind': kind.name,
        'item': item?.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory RecurrenceOccurrenceException.fromJson(
    Map<String, Object?> json,
  ) {
    final rawItem = json['item'];
    return RecurrenceOccurrenceException(
      id: json['id'] as String,
      seriesId: json['seriesId'] as String,
      occurrenceDate: DateTime.parse(json['occurrenceDate'] as String),
      kind: RecurrenceOccurrenceExceptionKind.values.byName(
        json['kind'] as String,
      ),
      item: rawItem == null
          ? null
          : MemoryItem.fromJson(Map<String, Object?>.from(rawItem as Map)),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

String recurrenceExceptionId(String seriesId, DateTime date) =>
    '$seriesId:${date.year.toString().padLeft(4, '0')}'
    '${date.month.toString().padLeft(2, '0')}'
    '${date.day.toString().padLeft(2, '0')}';
