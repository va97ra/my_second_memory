import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/foundation.dart';

import 'memory_editor_draft.dart';

/// Состояние формы редактора: всё, что человек выбрал, кроме набранного текста.
///
/// Текст живёт в контроллерах полей ввода, потому что ими владеет Flutter.
/// Всё остальное — здесь, отдельно от виджета, и потому проверяется без
/// запуска экрана.
@immutable
class MemoryEditorForm {
  const MemoryEditorForm({
    required this.type,
    required this.memoryDate,
    required this.status,
    required this.isUndated,
    this.timeMinutes,
    this.endMinutes,
    this.remindAt,
    this.reminderSoundUri,
    this.reminderSoundName,
    this.audioPath,
    this.audioDurationSeconds,
    this.imagePaths = const [],
    this.recurrenceFrequency,
    this.paymentCategory = PaymentCategory.other,
    this.subscriptionTermMonths,
    this.subscriptionTermDirty = false,
    this.birthYear,
    this.originalOccurrenceDate,
  });

  /// Пустая форма новой записи.
  factory MemoryEditorForm.blank({
    required DateTime date,
    required bool isUndated,
    int? timeMinutes,
    int? endMinutes,
  }) {
    return MemoryEditorForm(
      type: MemoryType.note,
      memoryDate: DateTime(date.year, date.month, date.day),
      status: MemoryStatus.active,
      isUndated: isUndated,
      // Отрезок приходит со шкалы дня: рамку нарисовали пальцем, и время
      // уже выбрано — переспрашивать его в редакторе незачем.
      timeMinutes: timeMinutes,
      endMinutes: endMinutes,
    );
  }

  /// Форма существующей записи.
  ///
  /// [subscriptionTermMonths] считается по серии и приходит снаружи: сама
  /// форма серий не видит.
  factory MemoryEditorForm.fromItem(
    MemoryItem item, {
    int? subscriptionTermMonths,
  }) {
    return MemoryEditorForm(
      // Вид, которого больше нет среди выбираемых, показывается как записка:
      // потерять запись из-за устаревшего вида нельзя.
      type: editableMemoryTypes.contains(item.type)
          ? item.type
          : MemoryType.note,
      memoryDate: item.memoryDate,
      status: item.status,
      isUndated: item.isUndated,
      timeMinutes: item.timeMinutes,
      endMinutes: item.endMinutes,
      remindAt: item.remindAt,
      reminderSoundUri: item.reminderSoundUri,
      reminderSoundName: item.reminderSoundName,
      audioPath: item.audioPath,
      audioDurationSeconds: item.audioDurationSeconds,
      imagePaths: List.unmodifiable(item.imagePaths),
      recurrenceFrequency: recurrenceFrequencyOf(item),
      paymentCategory: _paymentCategoryOf(item),
      subscriptionTermMonths: subscriptionTermMonths,
      birthYear: item.birthYear,
      // Перенесённое вхождение адресуется по исходной дате, иначе серия
      // разъезжается надвое.
      originalOccurrenceDate: item.seriesId == null ? null : item.memoryDate,
    );
  }

  final MemoryType type;
  final DateTime memoryDate;
  final MemoryStatus status;
  final bool isUndated;
  final int? timeMinutes;
  final int? endMinutes;
  final DateTime? remindAt;
  final String? reminderSoundUri;
  final String? reminderSoundName;
  final String? audioPath;
  final int? audioDurationSeconds;
  final List<String> imagePaths;
  final RecurrenceFrequency? recurrenceFrequency;
  final PaymentCategory paymentCategory;
  final int? subscriptionTermMonths;

  /// Срок подписки трогали в этой сессии редактирования — значит его нужно
  /// записать в серию, а не оставить прежним.
  final bool subscriptionTermDirty;
  final int? birthYear;
  final DateTime? originalOccurrenceDate;

  /// Есть ли во вложениях хоть что-то, что стоит сохранить само по себе.
  bool get hasAttachments => imagePaths.isNotEmpty || audioPath != null;

  /// Смена вида записи.
  ///
  /// День рождения и платёж по своей природе повторяются, поэтому вид сразу
  /// назначает повтор и напоминание: заранее — за день о дне рождения и за
  /// три дня о платеже, чтобы успеть что-то сделать.
  MemoryEditorForm withType(MemoryType next) {
    final wasPayment = type == MemoryType.payment;
    final becomesPayment = next == MemoryType.payment;
    var form = copyWith(type: next);

    switch (next) {
      case MemoryType.birthday:
        form = form.copyWith(
          recurrenceFrequency: RecurrenceFrequency.yearly,
          timeMinutes: timeMinutes ?? _defaultTimeMinutes,
          remindAt: _reminderBefore(
            form.memoryDate,
            timeMinutes ?? _defaultTimeMinutes,
            const Duration(days: 1),
          ),
        );
      case MemoryType.payment:
        form = form.copyWith(
          recurrenceFrequency: RecurrenceFrequency.monthly,
          timeMinutes: timeMinutes ?? _defaultTimeMinutes,
          remindAt: _reminderBefore(
            form.memoryDate,
            timeMinutes ?? _defaultTimeMinutes,
            const Duration(days: 3),
          ),
        );
      default:
        break;
    }

    if (!becomesPayment) {
      form = form.copyWith(clearSubscriptionTerm: true);
    }
    if (wasPayment != becomesPayment) {
      form = form.copyWith(subscriptionTermDirty: true);
    }
    return form;
  }

  /// Смена повтора.
  ///
  /// Срок подписки живёт только при ежемесячном платеже: как только повтор
  /// перестаёт быть ежемесячным, срок теряет смысл и должен быть стёрт в
  /// серии, а не остаться там от прошлой настройки.
  MemoryEditorForm withRecurrence(RecurrenceFrequency? next) {
    final keptTerm = keepsSubscriptionTerm(
      type: type,
      paymentCategory: paymentCategory.name,
      frequency: recurrenceFrequency,
    );
    final keepsTerm = keepsSubscriptionTerm(
      type: type,
      paymentCategory: paymentCategory.name,
      frequency: next,
    );
    var form = copyWith(
      recurrenceFrequency: next,
      clearRecurrence: next == null,
    );
    if (keptTerm && !keepsTerm) {
      form = form.copyWith(
        clearSubscriptionTerm: true,
        subscriptionTermDirty: true,
      );
    }
    return form;
  }

  /// Смена категории платежа. Срок есть только у подписки.
  MemoryEditorForm withPaymentCategory(PaymentCategory next) {
    var form = copyWith(
      paymentCategory: next,
      subscriptionTermDirty:
          paymentCategory == next ? subscriptionTermDirty : true,
    );
    if (next != PaymentCategory.subscription) {
      form = form.copyWith(clearSubscriptionTerm: true);
    }
    return form;
  }

  /// Черновик для сохранения. Текст и сумма приходят из полей ввода.
  MemoryEditorDraft toDraft({
    required String title,
    required String body,
    required int? amountMinor,
    required DateTime savedAt,
  }) {
    final isPayment = type == MemoryType.payment;
    return MemoryEditorDraft(
      type: type,
      title: title,
      body: body,
      timeMinutes: timeMinutes,
      endMinutes: endMinutes,
      remindAt: remindAt,
      reminderSoundUri: reminderSoundUri,
      reminderSoundName: reminderSoundName,
      memoryDate: DateTime(memoryDate.year, memoryDate.month, memoryDate.day),
      status: status,
      audioPath: audioPath,
      audioDurationSeconds: audioDurationSeconds,
      imagePaths: List.unmodifiable(imagePaths),
      savedAt: savedAt,
      repeatRule: recurrenceFrequency?.name,
      amountMinor: amountMinor,
      paymentCategory: isPayment ? paymentCategory.name : null,
      subscriptionTermMonths:
          isPayment && paymentCategory == PaymentCategory.subscription
              ? subscriptionTermMonths
              : null,
      subscriptionTermDirty: subscriptionTermDirty,
      birthYear: type == MemoryType.birthday ? birthYear : null,
      isUndated: isUndated,
    );
  }

  MemoryEditorForm copyWith({
    MemoryType? type,
    DateTime? memoryDate,
    MemoryStatus? status,
    bool? isUndated,
    int? timeMinutes,
    int? endMinutes,
    bool clearTime = false,
    DateTime? remindAt,
    bool clearReminder = false,
    String? reminderSoundUri,
    String? reminderSoundName,
    bool clearReminderSound = false,
    String? audioPath,
    int? audioDurationSeconds,
    bool clearAudio = false,
    List<String>? imagePaths,
    RecurrenceFrequency? recurrenceFrequency,
    bool clearRecurrence = false,
    PaymentCategory? paymentCategory,
    int? subscriptionTermMonths,
    bool clearSubscriptionTerm = false,
    bool? subscriptionTermDirty,
    int? birthYear,
    bool clearBirthYear = false,
    DateTime? originalOccurrenceDate,
  }) {
    return MemoryEditorForm(
      type: type ?? this.type,
      memoryDate: memoryDate ?? this.memoryDate,
      status: status ?? this.status,
      isUndated: isUndated ?? this.isUndated,
      timeMinutes: clearTime ? null : timeMinutes ?? this.timeMinutes,
      endMinutes: clearTime ? null : endMinutes ?? this.endMinutes,
      remindAt: clearReminder ? null : remindAt ?? this.remindAt,
      reminderSoundUri: clearReminderSound
          ? null
          : reminderSoundUri ?? this.reminderSoundUri,
      reminderSoundName: clearReminderSound
          ? null
          : reminderSoundName ?? this.reminderSoundName,
      audioPath: clearAudio ? null : audioPath ?? this.audioPath,
      audioDurationSeconds: clearAudio
          ? null
          : audioDurationSeconds ?? this.audioDurationSeconds,
      imagePaths: imagePaths ?? this.imagePaths,
      recurrenceFrequency: clearRecurrence
          ? null
          : recurrenceFrequency ?? this.recurrenceFrequency,
      paymentCategory: paymentCategory ?? this.paymentCategory,
      subscriptionTermMonths: clearSubscriptionTerm
          ? null
          : subscriptionTermMonths ?? this.subscriptionTermMonths,
      subscriptionTermDirty:
          subscriptionTermDirty ?? this.subscriptionTermDirty,
      birthYear: clearBirthYear ? null : birthYear ?? this.birthYear,
      originalOccurrenceDate:
          originalOccurrenceDate ?? this.originalOccurrenceDate,
    );
  }

  static const _defaultTimeMinutes = 9 * 60;

  static PaymentCategory _paymentCategoryOf(MemoryItem item) {
    for (final category in PaymentCategory.values) {
      if (category.name == item.paymentCategory) return category;
    }
    return PaymentCategory.other;
  }

  static DateTime _reminderBefore(
    DateTime date,
    int timeMinutes,
    Duration lead,
  ) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      timeMinutes ~/ 60,
      timeMinutes % 60,
    ).subtract(lead);
  }
}
