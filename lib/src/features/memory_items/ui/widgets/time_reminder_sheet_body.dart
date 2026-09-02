import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import 'inline_time_field.dart';

import 'reminder_toggle_tile.dart';
import 'time_reminder_sound_row.dart';

/// Что видно в листе времени и напоминания. Решения принимает сам лист.
class TimeReminderSheetBody extends StatelessWidget {
  const TimeReminderSheetBody({
    super.key,
    required this.timeMinutes,
    required this.reminderEnabled,
    required this.reminderMinutes,
    required this.onReminderTimeChanged,
    required this.reminderSupported,
    required this.soundName,
    required this.hasOwnSound,
    required this.busy,
    required this.error,
    required this.onTimeChanged,
    required this.onClearTime,
    required this.onToggleReminder,
    required this.onSelectSound,
    required this.onUseSystemSound,
    required this.onDone,
  });

  /// Время записи от полуночи, или null, если оно не задано.
  final int? timeMinutes;
  final bool reminderEnabled;

  /// Во сколько напомнить, от полуночи того же дня.
  final int? reminderMinutes;
  final ValueChanged<int> onReminderTimeChanged;

  /// Звуковые напоминания есть только на Android.
  final bool reminderSupported;

  final String? soundName;
  final bool hasOwnSound;
  final bool busy;
  final String? error;
  final ValueChanged<int> onTimeChanged;

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
            InlineTimeField(
              label: strings.time,
              minutes: timeMinutes,
              onChanged: onTimeChanged,
              // Время записи здесь только показывают: его задают рамкой.
              onClear: null,
              readOnly: true,
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
              InlineTimeField(
                key: const ValueKey('reminder_time_field'),
                label: Localizations.localeOf(context).languageCode == 'ru'
                    ? 'Напомнить в'
                    : 'Remind at',
                minutes: reminderMinutes,
                onChanged: onReminderTimeChanged,
                onClear: null,
              ),
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
