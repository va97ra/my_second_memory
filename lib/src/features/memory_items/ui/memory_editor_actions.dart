import 'dart:async';

import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../navigation/leave_after_frame.dart' as navigation;
import '../../../navigation/page_turn_navigation.dart';
import '../../recurrence/recurrence.dart';
import '../state/memory_attachment_service.dart';
import '../state/memory_editor_controller.dart';
import '../state/memory_item_commands.dart';
import '../state/memory_items_controller.dart';
import 'memory_attachment_actions.dart';
import 'memory_editor_schedule_actions.dart';
import 'widgets/delete_scope_sheet.dart';
import 'widgets/edit_scope_sheet.dart';
import 'widgets/memory_editor_menu.dart';
import 'widgets/multi_date_picker_sheet.dart';
import 'widgets/recurrence_picker_sheet.dart';

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

  /// Дата, время и сроки записи живут своим сценарием.
  MemoryEditorScheduleActions get schedule => MemoryEditorScheduleActions(
        context: context,
        ref: ref,
        controller: controller,
      );

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
      case MemoryEditorAction.date:
        unawaited(schedule.pickDate());
      case MemoryEditorAction.time:
        unawaited(schedule.openTimeAndReminder());
      case MemoryEditorAction.clearTime:
        schedule.clearTime();
      case MemoryEditorAction.reminder:
        unawaited(schedule.openTimeAndReminder());
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

  Future<void> confirmDelete(MemoryItem item) async {
    final scope = await askMemoryDelete(context, item);
    if (scope == null || !context.mounted) return;

    controller.discardPendingSave();
    await deleteMemory(ref, item, scope);
    if (context.mounted) {
      await goBack(skipSave: true);
    }
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

  /// Уводит с экрана исчезнувшей записи. Отложенное сохранение при этом
  /// отменяется: сохранять уже нечего и некуда.
  void leaveAfterFrame() {
    if (controller.isLeaving) return;
    controller.isLeaving = true;
    controller.discardPendingSave();
    navigation.leaveAfterFrame(context);
  }
}
