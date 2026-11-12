import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/state/notification_providers.dart';
import '../state/memory_editor_controller.dart';
import '../state/memory_editor_form.dart';
import 'widgets/birth_year_dialog.dart';
import 'widgets/subscription_term_sheet.dart';
import 'widgets/time_reminder_draft.dart';
import 'widgets/time_reminder_sheet.dart';

/// Когда запись стоит и сколько длится: дата, время с напоминанием, год
/// рождения и срок подписки. Каждое действие спрашивает человека и кладёт
/// ответ в форму; что с записью делать дальше, решает [MemoryEditorActions].
class MemoryEditorScheduleActions {
  const MemoryEditorScheduleActions({
    required this.context,
    required this.ref,
    required this.controller,
  });

  final BuildContext context;
  final WidgetRef ref;
  final MemoryEditorController controller;

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
      final remindAt = reminderAfterMove(
        form.remindAt,
        form.timeMinutes,
        memoryDate,
      );
      return form.copyWith(
        memoryDate: memoryDate,
        remindAt: remindAt,
        clearReminder: remindAt == null,
      );
    });
  }

  /// Время уходит вместе с напоминанием: напоминать не о чем, если запись
  /// больше не привязана к часу.
  void clearTime() => controller.applyForm(
        (form) => form.copyWith(clearTime: true, clearReminder: true),
      );

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
        initialReminderMinutes: _reminderMinutesOf(form),
        initialSoundUri: form.reminderSoundUri,
        initialSoundName: form.reminderSoundName,
        memoryDate: form.memoryDate,
        scheduler: ref.read(notificationServiceProvider),
      ),
    );
    if (result == null || !context.mounted) return;

    controller.applyForm((form) {
      final remindAt = result.reminderEnabled && result.timeMinutes != null
          ? _dateTimeFor(
              form.memoryDate,
              result.reminderMinutes ?? result.timeMinutes!,
            )
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

  /// Во сколько стоит напоминание записи, часами того же дня.
  ///
  /// Пусто — значит напоминания нет, и лист откроется на времени самой записи.
  static int? _reminderMinutesOf(MemoryEditorForm form) {
    final remindAt = form.remindAt;
    if (remindAt == null) return null;
    return remindAt.hour * 60 + remindAt.minute;
  }

  static DateTime _dateTimeFor(DateTime date, int minutes) =>
      DateTime(date.year, date.month, date.day, minutes ~/ 60, minutes % 60);
}
