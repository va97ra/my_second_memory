import '../../memory_items/domain/memory_item.dart';

enum RecurrenceFrequency {
  monthly,
  yearly;

  String label(String languageCode) => switch (this) {
        RecurrenceFrequency.monthly =>
          languageCode == 'ru' ? 'Ежемесячно' : 'Monthly',
        RecurrenceFrequency.yearly =>
          languageCode == 'ru' ? 'Ежегодно' : 'Yearly',
      };
}

enum PaymentCategory {
  subscription,
  utilities,
  meters,
  other;

  String label(String languageCode) {
    final ru = languageCode == 'ru';
    return switch (this) {
      PaymentCategory.subscription => ru ? 'Подписка' : 'Subscription',
      PaymentCategory.utilities => ru ? 'Квартплата' : 'Utilities',
      PaymentCategory.meters => ru ? 'Счётчики' : 'Meters',
      PaymentCategory.other => ru ? 'Другое' : 'Other',
    };
  }
}

class RecurrenceSeries {
  const RecurrenceSeries({
    required this.id,
    required this.frequency,
    required this.template,
    required this.startDate,
    required this.originItemId,
    required this.createdAt,
    required this.updatedAt,
    this.isEnabled = true,
    this.generatedThrough,
    this.endDate,
    this.historyThrough,
  });

  final String id;
  final RecurrenceFrequency frequency;
  final MemoryItem template;
  final DateTime startDate;
  final String originItemId;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? generatedThrough;
  final DateTime? endDate;
  final DateTime? historyThrough;

  RecurrenceSeries copyWith({
    RecurrenceFrequency? frequency,
    MemoryItem? template,
    DateTime? startDate,
    bool? isEnabled,
    DateTime? updatedAt,
    DateTime? generatedThrough,
    bool clearGeneratedThrough = false,
    DateTime? endDate,
    bool clearEndDate = false,
    DateTime? historyThrough,
  }) {
    return RecurrenceSeries(
      id: id,
      frequency: frequency ?? this.frequency,
      template: template ?? this.template,
      startDate: startDate ?? this.startDate,
      originItemId: originItemId,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      generatedThrough: clearGeneratedThrough
          ? null
          : generatedThrough ?? this.generatedThrough,
      endDate: clearEndDate ? null : endDate ?? this.endDate,
      historyThrough: historyThrough ?? this.historyThrough,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'frequency': frequency.name,
        'template': template.toJson(),
        'startDate': startDate.toIso8601String(),
        'originItemId': originItemId,
        'isEnabled': isEnabled,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'generatedThrough': generatedThrough?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'historyThrough': historyThrough?.toIso8601String(),
      };

  factory RecurrenceSeries.fromJson(Map<String, Object?> json) {
    return RecurrenceSeries(
      id: json['id'] as String,
      frequency: RecurrenceFrequency.values.byName(
        json['frequency'] as String,
      ),
      template: MemoryItem.fromJson(
        Map<String, Object?>.from(json['template'] as Map),
      ),
      startDate: DateTime.parse(json['startDate'] as String),
      originItemId: json['originItemId'] as String,
      isEnabled: json['isEnabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      generatedThrough: json['generatedThrough'] == null
          ? null
          : DateTime.parse(json['generatedThrough'] as String),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      historyThrough: json['historyThrough'] == null
          ? null
          : DateTime.parse(json['historyThrough'] as String),
    );
  }
}
