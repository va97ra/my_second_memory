import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

import 'reminder_sheet_tile.dart';

/// Выбор звука напоминания и возврат к системному.
class TimeReminderSoundRow extends StatelessWidget {
  const TimeReminderSoundRow({
    super.key,
    required this.soundName,
    required this.hasOwnSound,
    required this.busy,
    required this.onSelect,
    required this.onUseSystem,
  });

  final String? soundName;
  final bool hasOwnSound;
  final bool busy;
  final VoidCallback onSelect;
  final VoidCallback onUseSystem;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReminderSheetTile(
          icon: Icons.music_note_rounded,
          accentColor: const Color(0xFF7C3AED),
          title: strings.chooseSound,
          value: soundName ?? strings.systemAlarmSound,
          onTap: busy ? null : onSelect,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: !hasOwnSound || busy ? null : onUseSystem,
            child: Text(strings.useSystemSound),
          ),
        ),
      ],
    );
  }
}
