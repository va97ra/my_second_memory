import '../memory/memory_item.dart';
import '../memory/memory_type.dart';

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

/// Сохраняет ли запись срок подписки при такой частоте повтора.
///
/// Срок существует только у ежемесячного платежа-подписки. Любое отклонение —
/// другой вид записи, другая категория или другая частота — делает срок
/// бессмысленным, и он должен исчезнуть, а не остаться от прошлой настройки.
///
/// Принимает поля по отдельности, потому что спрашивают об этом и о
/// сохранённой записи, и о ещё не сохранённой форме редактора.
bool keepsSubscriptionTerm({
  required MemoryType type,
  required String? paymentCategory,
  required RecurrenceFrequency? frequency,
}) {
  return frequency == RecurrenceFrequency.monthly &&
      type == MemoryType.payment &&
      paymentCategory == PaymentCategory.subscription.name;
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
    this.endDate,
    this.subscriptionEndDate,
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

  /// A cutoff created by deleting this and later occurrences.
  final DateTime? endDate;

  /// The inclusive contractual end of a finite monthly subscription.
  final DateTime? subscriptionEndDate;
  /// Compatibility only: this build never materializes occurrences, so nothing
  /// reads this. It is still written so that a device left on an older build
  /// does not re-materialize the whole history behind us. Remove it once no
  /// such device is left.
  final DateTime? historyThrough;

  DateTime? get effectiveEndDate {
    final deletionEnd = endDate;
    final termEnd = subscriptionEndDate;
    if (deletionEnd == null) return termEnd;
    if (termEnd == null) return deletionEnd;
    return deletionEnd.isBefore(termEnd) ? deletionEnd : termEnd;
  }

  /// Серия для записи, которой только что назначили повтор.
  ///
  /// Повторную настройку той же записи серия переживает без потерь: id,
  /// начало и происхождение берутся у существующей серии, а не создаются
  /// заново, иначе одна запись обзавелась бы второй серией.
  factory RecurrenceSeries.forRecord({
    required MemoryItem record,
    required RecurrenceFrequency frequency,
    required DateTime now,
    RecurrenceSeries? existing,
  }) {
    final id = record.seriesId ?? 'recurrence_${record.id}';
    final template = record.copyWith(
      seriesId: id,
      repeatRule: frequency.name,
      isGeneratedOccurrence: false,
      updatedAt: now,
    );
    return RecurrenceSeries(
      id: id,
      frequency: frequency,
      template: template,
      startDate: existing?.startDate ?? template.memoryDate,
      originItemId: existing?.originItemId ?? template.id,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      endDate: existing?.endDate,
      subscriptionEndDate: keepsSubscriptionTerm(
        type: template.type,
        paymentCategory: template.paymentCategory,
        frequency: frequency,
      )
          ? existing?.subscriptionEndDate
          : null,
      historyThrough: DateTime(now.year, now.month, now.day),
    );
  }

  RecurrenceSeries copyWith({
    RecurrenceFrequency? frequency,
    MemoryItem? template,
    DateTime? startDate,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? endDate,
    bool clearEndDate = false,
    DateTime? subscriptionEndDate,
    bool clearSubscriptionEndDate = false,
    DateTime? historyThrough,
  }) {
    return RecurrenceSeries(
      id: id,
      frequency: frequency ?? this.frequency,
      template: template ?? this.template,
      startDate: startDate ?? this.startDate,
      originItemId: originItemId,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      endDate: clearEndDate ? null : endDate ?? this.endDate,
      subscriptionEndDate: clearSubscriptionEndDate
          ? null
          : subscriptionEndDate ?? this.subscriptionEndDate,
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
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'subscriptionEndDate': subscriptionEndDate?.toIso8601String(),
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
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toLocal(),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      subscriptionEndDate: json['subscriptionEndDate'] == null
          ? null
          : DateTime.parse(json['subscriptionEndDate'] as String),
      historyThrough: json['historyThrough'] == null
          ? null
          : DateTime.parse(json['historyThrough'] as String),
    );
  }
}
