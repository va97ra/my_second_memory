import 'package:ez_domain/ez_domain.dart';

import '../../recurrence/recurrence.dart';
import 'memory_editor_draft.dart';
import 'memory_items_controller.dart';

/// Чем закончилось сохранение черновика.
class MemoryEditorSaveOutcome {
  const MemoryEditorSaveOutcome({
    required this.item,
    required this.created,
    this.seriesId,
  });

  /// Запись в том виде, в каком она сохранена.
  final MemoryItem item;

  /// Запись заведена только что, а не обновлена.
  final bool created;

  /// Серия, которой запись принадлежит после сохранения, если повтор включён.
  final String? seriesId;
}

/// Сохранение черновика редактора.
///
/// Здесь живут все решения о том, куда именно уходит правка: в обычную строку,
/// в шаблон серии или в переопределение одного вхождения. Раньше эти решения
/// сидели внутри виджета редактора и потому не проверялись ничем, кроме
/// прогона всего экрана.
class MemoryEditorSaver {
  const MemoryEditorSaver({
    required MemoryItemsController items,
    required RecurrenceSeriesController series,
  })  : _items = items,
        _series = series;

  final MemoryItemsController _items;
  final RecurrenceSeriesController _series;

  /// [existing] — запись, которую редактируют, или null для новой.
  ///
  /// [refreshSeriesTemplate] означает, что серию нужно перезаписать шаблоном
  /// целиком: так ведёт себя только что созданная запись, пока пользователь
  /// дописывает её первые слова.
  ///
  /// [editFutureOccurrences] — правка «эта и будущие».
  ///
  /// [originalOccurrenceDate] — исходная дата вхождения. Перенесённое
  /// вхождение видно на новой дате, но адресуется по исходной, иначе серия
  /// разъезжается надвое.
  Future<MemoryEditorSaveOutcome> persist(
    MemoryEditorDraft draft, {
    required MemoryItem? existing,
    required bool refreshSeriesTemplate,
    required bool editFutureOccurrences,
    required DateTime? originalOccurrenceDate,
  }) async {
    final frequency = draft.repeatRule == null
        ? null
        : RecurrenceFrequency.values.byName(draft.repeatRule!);

    if (existing == null) {
      return _create(draft, frequency);
    }
    return _update(
      draft,
      existing: existing,
      frequency: frequency,
      refreshSeriesTemplate: refreshSeriesTemplate,
      editFutureOccurrences: editFutureOccurrences,
      originalOccurrenceDate: originalOccurrenceDate,
    );
  }

  Future<MemoryEditorSaveOutcome> _create(
    MemoryEditorDraft draft,
    RecurrenceFrequency? frequency,
  ) async {
    final created = MemoryItem(
      id: draft.savedAt.microsecondsSinceEpoch.toString(),
      type: draft.type,
      title: draft.title,
      body: draft.body,
      timeMinutes: draft.timeMinutes,
      endMinutes: draft.endMinutes,
      remindAt: draft.remindAt,
      reminderSoundUri: draft.reminderSoundUri,
      reminderSoundName: draft.reminderSoundName,
      memoryDate: draft.memoryDate,
      createdAt: draft.savedAt,
      updatedAt: draft.savedAt,
      status: draft.status,
      audioPath: draft.audioPath,
      audioDurationSeconds: draft.audioDurationSeconds,
      imagePaths: draft.imagePaths,
      repeatRule: draft.repeatRule,
      amountMinor: draft.amountMinor,
      paymentCategory: draft.paymentCategory,
      birthYear: draft.birthYear,
      isUndated: draft.isUndated,
    );
    await _items.add(created);

    if (frequency == null) {
      return MemoryEditorSaveOutcome(item: created, created: true);
    }
    final series = await _series.setFrequency(created, frequency);
    await _applySubscriptionTerm(draft, series.id, updatesSeries: true);
    return MemoryEditorSaveOutcome(
      item: created,
      created: true,
      seriesId: series.id,
    );
  }

  Future<MemoryEditorSaveOutcome> _update(
    MemoryEditorDraft draft, {
    required MemoryItem existing,
    required RecurrenceFrequency? frequency,
    required bool refreshSeriesTemplate,
    required bool editFutureOccurrences,
    required DateTime? originalOccurrenceDate,
  }) async {
    final updated = _merge(existing, draft);

    if (frequency == null) {
      await _items.update(updated);
      return MemoryEditorSaveOutcome(
        item: updated,
        created: false,
        seriesId: updated.seriesId,
      );
    }

    // Строка существует не всегда: вхождение повтора обычно спроецировано.
    final hasRow = _items.items.any((entry) => entry.id == existing.id);
    final startsSeries = refreshSeriesTemplate && existing.seriesId != null ||
        existing.repeatRule != frequency.name ||
        existing.seriesId == null;

    if (startsSeries) {
      if (hasRow) await _items.update(updated);
      final series = await _series.setFrequency(updated, frequency);
      await _applySubscriptionTerm(draft, series.id, updatesSeries: true);
      return MemoryEditorSaveOutcome(
        item: updated,
        created: false,
        seriesId: series.id,
      );
    }

    if (editFutureOccurrences) {
      final series = await _series.applyToFuture(
        updated,
        occurrenceDate: originalOccurrenceDate,
      );
      await _applySubscriptionTerm(
        draft,
        series?.id,
        updatesSeries: series != null,
      );
      return MemoryEditorSaveOutcome(
        item: updated,
        created: false,
        seriesId: series?.id,
      );
    }

    // Правка принадлежит тому вхождению, на котором сделана, и живёт в
    // переопределении его исходной даты — независимо от того, была ли под
    // вхождением строка.
    await _series.saveOccurrenceOverride(
      updated,
      occurrenceDate: originalOccurrenceDate,
    );
    return MemoryEditorSaveOutcome(
      item: updated,
      created: false,
      seriesId: updated.seriesId,
    );
  }

  MemoryItem _merge(MemoryItem existing, MemoryEditorDraft draft) {
    return existing.copyWith(
      type: draft.type,
      title: draft.title,
      body: draft.body,
      timeMinutes: draft.timeMinutes,
      endMinutes: draft.endMinutes,
      clearTime: draft.timeMinutes == null,
      remindAt: draft.remindAt,
      clearReminder: draft.remindAt == null,
      reminderSoundUri: draft.reminderSoundUri,
      reminderSoundName: draft.reminderSoundName,
      memoryDate: draft.memoryDate,
      status: draft.status,
      audioPath: draft.audioPath,
      audioDurationSeconds: draft.audioDurationSeconds,
      clearAudio: draft.audioPath == null,
      imagePaths: draft.imagePaths,
      repeatRule: draft.repeatRule,
      clearRepeatRule: draft.repeatRule == null,
      amountMinor: draft.amountMinor,
      clearAmount: draft.amountMinor == null,
      paymentCategory: draft.paymentCategory,
      clearPaymentCategory: draft.paymentCategory == null,
      birthYear: draft.birthYear,
      clearBirthYear: draft.birthYear == null,
      isUndated: draft.isUndated,
      updatedAt: draft.savedAt,
    );
  }

  /// Срок подписки принадлежит серии, а не вхождению, поэтому он пишется
  /// только когда сохранение действительно трогало серию.
  Future<void> _applySubscriptionTerm(
    MemoryEditorDraft draft,
    String? seriesId, {
    required bool updatesSeries,
  }) async {
    if (seriesId == null ||
        !updatesSeries ||
        draft.repeatRule == null ||
        !draft.subscriptionTermDirty) {
      return;
    }
    await _series.setTermMonths(seriesId, draft.subscriptionTermMonths);
  }
}
