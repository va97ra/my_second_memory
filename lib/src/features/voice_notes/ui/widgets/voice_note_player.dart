import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/localization/app_strings.dart';
import '../../state/voice_note_playback_controller.dart';

class VoiceNotePlayer extends ConsumerWidget {
  const VoiceNotePlayer({
    required this.path,
    this.recordedAt,
    this.durationSeconds,
    super.key,
  });

  final String path;
  final DateTime? recordedAt;
  final int? durationSeconds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final meta = _metaText(context);
    final playback = ref.watch(voiceNotePlaybackProvider);

    return StreamBuilder<PlayerState>(
      stream: playback.playerStateStream,
      builder: (context, snapshot) {
        final isPlaying =
            playback.activePath == path && (snapshot.data?.playing ?? false);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 7, 10, 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton.filledTonal(
                  tooltip: strings.play,
                  onPressed: () => playback.toggle(path),
                  icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                  style: IconButton.styleFrom(
                    fixedSize: const Size.square(36),
                    padding: EdgeInsets.zero,
                    foregroundColor: colorScheme.primary,
                    backgroundColor:
                        colorScheme.primary.withValues(alpha: 0.12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        strings.voiceMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      if (meta.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _metaText(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final parts = <String>[];
    final recordedAt = this.recordedAt;
    final durationSeconds = this.durationSeconds;

    if (recordedAt != null) {
      final date = DateFormat.yMMMd(locale).format(recordedAt);
      parts.add(AppStrings.of(context).isRu ? 'Запись с $date' : 'From $date');
    }
    if (durationSeconds != null) {
      parts.add(_formatDuration(durationSeconds));
    }

    return parts.join(' • ');
  }

  String _formatDuration(int totalSeconds) {
    final safeSeconds = totalSeconds < 0 ? 0 : totalSeconds;
    final minutes = safeSeconds ~/ 60;
    final seconds = safeSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
