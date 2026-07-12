import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../data/notification_service.dart';

Future<ReminderSoundSource?> showReminderSoundSourcePicker(
  BuildContext context,
) {
  final strings = AppStrings.of(context);
  return showModalBottomSheet<ReminderSoundSource>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Text(
                  strings.chooseSound,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.alarm_outlined),
              title: Text(strings.systemMelody),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(context, ReminderSoundSource.system),
            ),
            ListTile(
              leading: const Icon(Icons.audio_file_outlined),
              title: Text(strings.chooseAudioFile),
              subtitle: Text(strings.chooseAudioFileSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  Navigator.pop(context, ReminderSoundSource.audioFile),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<ReminderSoundSelection?> pickReminderSound(
  BuildContext context,
  ReminderScheduler scheduler, {
  String? currentUri,
}) async {
  final source = await showReminderSoundSourcePicker(context);
  if (source == null || !context.mounted) return null;
  if (source == ReminderSoundSource.audioFile) {
    return scheduler.selectSound(
      currentUri: currentUri,
      source: ReminderSoundSource.audioFile,
    );
  }

  final sounds = await scheduler.systemSounds();
  if (sounds.isEmpty || !context.mounted) {
    throw StateError('No system alarm sounds');
  }
  return showModalBottomSheet<ReminderSoundSelection>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.72,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppStrings.of(context).systemMelody,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: sounds.length,
                itemBuilder: (context, index) {
                  final sound = sounds[index];
                  final selected = sound.uri == currentUri;
                  return ListTile(
                    leading: const Icon(Icons.music_note_outlined),
                    title: Text(sound.name),
                    trailing: selected ? const Icon(Icons.check) : null,
                    onTap: () => Navigator.pop(context, sound),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
