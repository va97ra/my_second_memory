import '../memory/memory_item.dart';
import 'recurrence_projection_service.dart';
import 'recurrence_series.dart';

bool _templateKeepsTerm(MemoryItem template, RecurrenceFrequency frequency) =>
    keepsSubscriptionTerm(
      type: template.type,
      paymentCategory: template.paymentCategory,
      frequency: frequency,
    );

/// Что должно получиться из правки «эта и будущие».
class RecurrenceSplit {
  const RecurrenceSplit({required this.replacement, this.ended});

  /// Серия, которой принадлежит правка: либо обновлённая исходная, либо новая.
  final RecurrenceSeries replacement;

  /// Исходная серия, закрытая днём раньше среза. Null, если делить не
  /// пришлось.
  final RecurrenceSeries? ended;

  bool get splits => ended != null;
}

/// Разделение серии правкой «эта и будущие».
///
/// [cutoff] — исходная дата вхождения, с которого правка вступает в силу;
/// перенесённое вхождение адресуется по ней, а не по видимой дате.
///
/// Правка на самом старте серии ничего не делит: она меняет серию на месте.
/// Иначе одна запись обзаводилась бы цепочкой серий — автосохранение
/// срабатывает на каждой паузе в наборе, и каждый раз рождалась бы новая.
RecurrenceSplit splitSeriesForFutureEdit({
  required RecurrenceSeries current,
  required MemoryItem edited,
  required DateTime cutoff,
  required DateTime now,
}) {
  final replacementStart = dateOnly(edited.memoryDate);
  final startsSeries = current.originItemId == edited.id &&
      dateKey(current.startDate) == dateKey(cutoff);

  if (startsSeries) {
    final template = _linkToSeries(edited, current.id, current.frequency, now);
    final keepsTerm = _templateKeepsTerm(template, current.frequency);
    return RecurrenceSplit(
      replacement: current.copyWith(
        template: template,
        startDate: replacementStart,
        subscriptionEndDate: keepsTerm ? current.subscriptionEndDate : null,
        clearSubscriptionEndDate: !keepsTerm,
        updatedAt: now,
      ),
    );
  }

  final newId = '${current.id}_${dateKey(cutoff)}_${now.microsecondsSinceEpoch}';
  final template = _linkToSeries(edited, newId, current.frequency, now);
  return RecurrenceSplit(
    ended: current.copyWith(
      endDate: cutoff.subtract(const Duration(days: 1)),
      updatedAt: now,
    ),
    replacement: RecurrenceSeries(
      id: newId,
      frequency: current.frequency,
      template: template,
      startDate: replacementStart,
      originItemId: template.id,
      createdAt: now,
      updatedAt: now,
      endDate: current.endDate,
      subscriptionEndDate: _templateKeepsTerm(template, current.frequency)
          ? current.subscriptionEndDate
          : null,
      historyThrough: dateOnly(now),
    ),
  );
}

MemoryItem _linkToSeries(
  MemoryItem edited,
  String seriesId,
  RecurrenceFrequency frequency,
  DateTime now,
) {
  return edited.copyWith(
    seriesId: seriesId,
    repeatRule: frequency.name,
    isGeneratedOccurrence: false,
    updatedAt: now,
  );
}
