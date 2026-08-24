import 'dart:async';

import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../navigation/page_turn_navigation.dart';
import '../../../shared/state/notification_providers.dart';
import '../../recurrence/state/recurrence_controller.dart';
import '../state/memory_attachment_service.dart';
import '../state/memory_editor_controller.dart';
import '../state/memory_items_controller.dart';
import 'memory_attachment_actions.dart';
import 'widgets/birth_year_dialog.dart';
import 'widgets/delete_scope_sheet.dart';
import 'widgets/edit_scope_sheet.dart';
import 'widgets/memory_editor_menu.dart';
import 'widgets/multi_date_picker_sheet.dart';
import 'widgets/recurrence_picker_sheet.dart';
import 'widgets/subscription_term_sheet.dart';
import 'widgets/time_reminder_sheet.dart';

/// Что происходит по нажатию в редакторе записи.
///
/// Каждое действие устроено одинаково: спросить человека, а полученный ответ
/// отдать контроллеру. Поэтому здесь есть `BuildContext`, а в контроллере —
/// нет.
class MemoryEditorActions {
  const MemoryEditorActions({
    required this.context,
    required this.ref,
    required this.controller,
    required this.attachments,
    required this.imagePicker,
  });

  final BuildContext context;
  final WidgetRef ref;
  final MemoryEditorController controller;
  final MemoryAttachmentService attachments;
  final ImagePicker imagePicker;

  /// Вложения записи живут своим сценарием.
  MemoryAttachmentActions get media => MemoryAttachmentActions(
        context: context,
        controller: controller,
        attachments: attachments,
        imagePicker: imagePicker,
      );

  /// Пункт меню записи. Пункты, которым нужна сохранённая запись, у
  /// черновика просто ничего не делают.
  void runMenuAction(MemoryEditorAction action, MemoryItem? item) {
    switch (action) {
      case MemoryEditorAction.repeat:
        unawaited(openRepeatPicker());
      case MemoryEditorAction.duplicate:
        if (item != null) unawaited(duplicateToDates(item));
      case MemoryEditorAction.applyToFuture:
        if (item != null) applyToFuture(item);
      case MemoryEditorAction.delete:
        if (item != null) unawaited(confirmDelete(item));
    }
  }

  Future<void> pickBirthYear() async {
    final year =
        await askBirthYear(context, initial: controller.form.birthYear);
    if (year == null || !context.mounted) return;
    controller.applyForm((form) => form.copyWith(birthYear: year));
  }

  Future<void> pickSubscriptionTerm() async {
    final months = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SubscriptionTermSheet(
        initialMonths: controller.form.subscriptionTermMonths,
      ),
    );
    if (months == null || !context.mounted) return;
    controller.applyForm(
      (form) => form.copyWith(
        subscriptionTermMonths: months == 0 ? null : months,
        clearSubscriptionTerm: months == 0,
        subscriptionTermDirty: true,
      ),
    );
  }

  Future<void> openRepeatPicker() async {
    final choice = await askRecurrence(
      context,
      current: controller.form.recurrenceFrequency,
    );
    if (choice == null || !context.mounted) return;

    final item = controller.readItem();
    controller.update(
      () => controller.form = controller.form.withRecurrence(choice.frequency),
    );
    // Снятый повтор нужно убрать и из серии, иначе запись вернётся из неё на
    // следующем пересчёте. Отложенное сохранение ждёт этого.
    if (choice.frequency == null && item?.seriesId != null) {
      await ref
          .read(recurrenceSeriesControllerProvider.notifier)
          .clearFrequency(item!);
    }
    controller.scheduleAutosave();
  }

  Future<void> askScope() async {
    final applyFuture = await askEditScope(context);
    if (applyFuture == null || !context.mounted) return;
    controller.update(() => controller.editFutureOccurrences = applyFuture);
  }

  void applyToFuture(MemoryItem item) {
    controller.update(() => controller.editFutureOccurrences = true);
    ref.read(recurrenceSeriesControllerProvider.notifier).applyToFuture(item);
  }

  Future<void> duplicateToDates(MemoryItem item) async {
    await controller.flushAutosave();
    if (!context.mounted) return;
    final dates = await showModalBottomSheet<List<DateTime>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => MultiDatePickerSheet(sourceDate: item.memoryDate),
    );
    if (dates == null || dates.isEmpty || !context.mounted) return;

    final copies = await ref
        .read(memoryItemsControllerProvider.notifier)
        .duplicateToDates(item, dates);
    if (!context.mounted) return;
    final ru = Localizations.localeOf(context).languageCode == 'ru';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ru
              ? 'Создано копий: ${copies.length}'
              : 'Copies created: ${copies.length}',
        ),
      ),
    );
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.form.memoryDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    controller.applyForm((form) {
      final memoryDate = DateTime(picked.year, picked.month, picked.day);
      // Напоминание привязано ко дню записи: переехала запись — переезжает и
      // оно, а если новое время уже прошло, напоминать не о чем.
      var remindAt = form.remindAt;
      if (form.remindAt != null && form.timeMinutes != null) {
        final next = _dateTimeFor(memoryDate, form.timeMinutes!);
        remindAt = next.isAfter(DateTime.now()) ? next : null;
      }
      return form.copyWith(
        memoryDate: memoryDate,
        remindAt: remindAt,
        clearReminder: remindAt == null,
      );
    });
  }

  Future<void> openTimeAndReminder() async {
    final form = controller.form;
    final result = await showModalBottomSheet<TimeReminderDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => TimeReminderSheet(
        initialTimeMinutes: form.timeMinutes,
        initialReminderEnabled: form.remindAt != null,
        initialSoundUri: form.reminderSoundUri,
        initialSoundName: form.reminderSoundName,
        memoryDate: form.memoryDate,
        scheduler: ref.read(notificationServiceProvider),
      ),
    );
    if (result == null || !context.mounted) return;

    controller.applyForm((form) {
      final remindAt = result.reminderEnabled && result.timeMinutes != null
          ? _dateTimeFor(form.memoryDate, result.timeMinutes!)
          : null;
      return form.copyWith(
        timeMinutes: result.timeMinutes,
        clearTime: result.timeMinutes == null,
        remindAt: remindAt,
        clearReminder: remindAt == null,
        reminderSoundUri: result.soundUri,
        reminderSoundName: result.soundName,
        clearReminderSound: result.soundUri == null,
      );
    });
  }

  Future<void> confirmDelete(MemoryItem item) async {
    final scope = item.seriesId == null
        ? MemoryDeleteScope.one
        : await askDeleteScope(context);
    if (scope == null || !context.mounted) return;

    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.deleteRecordQuestion),
        content: Text(item.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    controller.discardPendingSave();
    await _delete(item, scope);
    if (context.mounted) {
      await goBack(skipSave: true);
    }
  }

  Future<void> _delete(MemoryItem item, MemoryDeleteScope scope) async {
    final series = ref.read(recurrenceSeriesControllerProvider.notifier);
    final seriesId = item.seriesId;
    if (scope == MemoryDeleteScope.series && seriesId != null) {
      return series.deleteSeries(seriesId);
    }
    if (scope == MemoryDeleteScope.future && seriesId != null) {
      return series.deleteFromDate(seriesId, item.memoryDate, occurrence: item);
    }
    if (seriesId != null) {
      return series.deleteOccurrence(item);
    }
    return ref.read(memoryItemsControllerProvider.notifier).delete(item.id);
  }

  Future<void> goBack({bool skipSave = false}) async {
    if (controller.isLeaving) return;
    controller.isLeaving = true;
    if (!skipSave) {
      await controller.flushAutosave();
      if (controller.hasSaveError) {
        controller.isLeaving = false;
        return;
      }
    }
    if (!context.mounted) return;

    controller.update(() => controller.allowPop = true);
    if (context.canPop()) {
      await context.pageTurnPop();
      return;
    }
    await context.pageTurnGo('/', direction: PageTurnDirection.backward);
  }

  /// Уводит с экрана исчезнувшей записи после того, как кадр дорисован.
  ///
  /// Без перелистывания: анимировать нечего, а сама анимация в этот момент
  /// может быть занята другим переходом и отменила бы уход.
  void leaveAfterFrame() {
    if (controller.isLeaving) return;
    controller.isLeaving = true;
    controller.discardPendingSave();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    });
  }

  DateTime _dateTimeFor(DateTime date, int minutes) =>
      DateTime(date.year, date.month, date.day, minutes ~/ 60, minutes % 60);
}
