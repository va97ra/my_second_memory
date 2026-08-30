import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import 'reminder_sheet_tile.dart';
import 'reminder_toggle_tile.dart';
import 'time_reminder_sound_row.dart';

/// Что видно в листе времени и напоминания. Решения принимает сам лист.
class TimeReminderSheetBody extends StatelessWidget {
  const TimeReminderSheetBody({
    super.key,
    required this.timeMinutes,
    required this.reminderEnabled,
    required this.reminderSupported,
    required this.soundName,
    required this.hasOwnSound,
    required this.busy,
    required this.error,
    required this.onPickTime,
    required this.onClearTime,
    required this.onToggleReminder,
    required this.onSelectSound,
    required this.onUseSystemSound,
    required this.onDone,
  });

  /// Время записи от полуночи, или null, если оно не задано.
  final int? timeMinutes;
  final bool reminderEnabled;

  /// Звуковые напоминания есть только на Android.
  final bool reminderSupported;

  final String? soundName;
  final bool hasOwnSound;
  final bool busy;
  final String? error;
  final VoidCallback onPickTime;

  /// Null, когда времени и так нет.
  final VoidCallback? onClearTime;

  final ValueChanged<bool> onToggleReminder;
  final VoidCallback onSelectSound;
  final VoidCallback onUseSystemSound;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return SafeArea(
      child: KeyboardInsetPadding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.timeAndReminder,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            ReminderSheetTile(
              icon: Icons.schedule_rounded,
              accentColor: const Color(0xFF218CFF),
              title: strings.time,
              value: timeMinutes == null
                  ? strings.timeNotSet
                  : formatMinutesOfDay(timeMinutes!),
              onTap: onPickTime,
              trailing: onClearTime == null
                  ? null
                  : IconButton(
                      tooltip: strings.delete,
                      onPressed: onClearTime,
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
            ),
            const SizedBox(height: 5),
            ReminderToggleTile(
              accentColor: Theme.of(context).colorScheme.primary,
              title: strings.soundNotification,
              subtitle: reminderSupported ? null : strings.androidOnlyReminder,
              value: reminderEnabled,
              onChanged: !reminderSupported || busy ? null : onToggleReminder,
            ),
            if (reminderEnabled) ...[
              const SizedBox(height: 5),
              TimeReminderSoundRow(
                soundName: soundName,
                hasOwnSound: hasOwnSound,
                busy: busy,
                onSelect: onSelectSound,
                onUseSystem: onUseSystemSound,
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error!,
                key: const ValueKey('memory_reminder_error'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
            const SizedBox(height: 10),
            NotebookActionButton(
              key: const ValueKey('memory_reminder_done'),
              onPressed: busy ? null : onDone,
              icon: busy
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              child: Text(strings.ready),
            ),
          ],
        ),
      ),
    );
  }
}
