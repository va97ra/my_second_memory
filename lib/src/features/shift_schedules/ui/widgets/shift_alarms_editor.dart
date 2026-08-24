import 'package:ez_core/ez_core.dart';
import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../notifications/state/notification_providers.dart';
import '../../../notifications/ui/reminder_sound_picker.dart';
import 'shift_alarm_editor_card.dart';

/// Будильники графика: карточки и всё, что происходит по нажатию на них.
///
/// Второй будильник показывается только там, где смена переходит через
/// полночь, — это решает [supportsNextDayAlarm], а не сам виджет.
class ShiftAlarmsEditor extends ConsumerWidget {
  const ShiftAlarmsEditor({
    super.key,
    required this.alarms,
    required this.supportsNextDayAlarm,
    required this.onChanged,
  });

  final List<ShiftAlarm> alarms;
  final bool supportsNextDayAlarm;
  final ValueChanged<List<ShiftAlarm>> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final visibleCount = supportsNextDayAlarm ? 2 : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < visibleCount; index++) ...[
          if (index > 0) const SizedBox(height: 8),
          ShiftAlarmEditorCard(
            title: index == 1
                ? strings.nextDayShiftAlarm
                : strings.shiftAlarmNumber(1),
            subtitle: index == 1
                ? strings.nextDayShiftAlarmSubtitle
                : strings.shiftAlarmSubtitle,
            alarm: alarms[index],
            onToggle: (value) => _toggle(context, ref, index, value),
            onPickTime: () => _pickTime(context, index),
            onPickSound: () => _pickSound(context, ref, index),
          ),
        ],
      ],
    );
  }

  /// Будильник включается только после разрешения на уведомления: без него
  /// он не сработает, а в форме выглядел бы включённым.
  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    int index,
    bool enabled,
  ) async {
    if (enabled) {
      final allowed =
          await ref.read(notificationServiceProvider).requestPermissions();
      if (!allowed) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.of(context).reminderPermissionRequired),
            ),
          );
        }
        return;
      }
    }
    if (context.mounted) {
      _replace(index, alarms[index].copyWith(isEnabled: enabled));
    }
  }

  Future<void> _pickTime(BuildContext context, int index) async {
    final alarm = alarms[index];
    final picked = await showTimePicker(
      context: context,
      initialEntryMode: TimePickerEntryMode.inputOnly,
      initialTime: TimeOfDay(
        hour: alarm.timeMinutes ~/ 60,
        minute: alarm.timeMinutes % 60,
      ),
    );
    if (picked != null && context.mounted) {
      _replace(
        index,
        alarm.copyWith(timeMinutes: picked.hour * 60 + picked.minute),
      );
    }
  }

  Future<void> _pickSound(
    BuildContext context,
    WidgetRef ref,
    int index,
  ) async {
    final alarm = alarms[index];
    final ReminderSoundSelection? sound;
    try {
      sound = await pickReminderSound(
        context,
        ref.read(notificationServiceProvider),
        currentUri: alarm.soundUri,
      );
    } catch (_) {
      // Выбор звука опирается на системный экран, которого на части устройств
      // нет. Тогда будильник остаётся со звуком по умолчанию.
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppStrings.of(context).soundPickerUnavailable)),
        );
      }
      return;
    }
    if (sound != null && context.mounted) {
      _replace(
        index,
        alarm.copyWith(soundUri: sound.uri, soundName: sound.name),
      );
    }
  }

  void _replace(int index, ShiftAlarm alarm) {
    onChanged([
      for (var slot = 0; slot < alarms.length; slot++)
        slot == index ? alarm : alarms[slot],
    ]);
  }
}
