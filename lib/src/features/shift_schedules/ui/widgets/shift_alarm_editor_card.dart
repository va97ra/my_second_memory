import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import '../../../settings/settings.dart';
import 'shift_alarm_action_row.dart';
import 'shift_editor_row.dart';

/// Один будильник смены: включение, а у включённого ещё время и звук.
class ShiftAlarmEditorCard extends StatelessWidget {
  const ShiftAlarmEditorCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.alarm,
    required this.onToggle,
    required this.onPickTime,
    required this.onPickSound,
  });

  final String title;
  final String subtitle;
  final ShiftAlarm alarm;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickTime;
  final VoidCallback onPickSound;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ShiftEditorRow(
          icon: Icons.alarm_rounded,
          color: Theme.of(context).colorScheme.primary,
          title: title,
          subtitle: subtitle,
          lit: alarm.isEnabled,
          toggled: alarm.isEnabled,
          trailing: SettingsToggle(value: alarm.isEnabled),
          onTap: () => onToggle(!alarm.isEnabled),
        ),
        if (alarm.isEnabled) ...[
          ShiftAlarmActionRow(
            icon: Icons.schedule_rounded,
            title: strings.time,
            value: formatMinutesOfDay(alarm.timeMinutes),
            onTap: onPickTime,
          ),
          ShiftAlarmActionRow(
            icon: Icons.music_note_rounded,
            title: strings.chooseSound,
            value: alarm.soundName ?? strings.systemAlarmSound,
            onTap: onPickSound,
          ),
        ],
      ],
    );
  }
}
