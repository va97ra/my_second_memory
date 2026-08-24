import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import 'shift_alarm_action_row.dart';

/// Карточка одного будильника смены: включение, время и звук.
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
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Row(
                children: [
                  Icon(
                    Icons.alarm_rounded,
                    size: 20,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colors.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Switch(value: alarm.isEnabled, onChanged: onToggle),
                ],
              ),
            ),
          ),
          if (alarm.isEnabled) ...[
            const Divider(height: 1, indent: 12, endIndent: 12),
            ShiftAlarmActionRow(
              icon: Icons.schedule_rounded,
              title: strings.time,
              value: formatMinutesOfDay(alarm.timeMinutes),
              onTap: onPickTime,
            ),
            const Divider(height: 1, indent: 44, endIndent: 12),
            ShiftAlarmActionRow(
              icon: Icons.music_note_rounded,
              title: strings.chooseSound,
              value: alarm.soundName ?? strings.systemAlarmSound,
              onTap: onPickSound,
            ),
          ],
        ],
      ),
    );
  }
}
