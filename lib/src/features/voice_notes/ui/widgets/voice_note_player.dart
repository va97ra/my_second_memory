import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/localization/app_strings.dart';

class VoiceNotePlayer extends StatefulWidget {
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
  State<VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<VoiceNotePlayer> {
  final _player = AudioPlayer();
  bool _isPlaying = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final meta = _metaText(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDE7F3)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 7, 10, 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton.filledTonal(
              tooltip: strings.play,
              onPressed: _toggle,
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              style: IconButton.styleFrom(
                fixedSize: const Size.square(36),
                padding: EdgeInsets.zero,
                foregroundColor: colorScheme.primary,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
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
                          color: const Color(0xFF172033),
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: const Color(0xFF64748B),
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
  }

  String _metaText(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final parts = <String>[];
    final recordedAt = widget.recordedAt;
    final durationSeconds = widget.durationSeconds;

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

  Future<void> _toggle() async {
    if (_isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
      return;
    }

    await _player.setFilePath(widget.path);
    if (mounted) {
      setState(() => _isPlaying = true);
    }
    await _player.play();
    if (mounted) {
      setState(() => _isPlaying = false);
    }
  }
}
