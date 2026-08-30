import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import '../../../../shared/ui/media/voice_note_player.dart';
import 'media_delete_menu.dart';
import 'record_editor_actions.dart';
import 'record_editor_field.dart';
import 'record_editor_images.dart';
import 'record_editor_layout.dart';
import 'recording_pill.dart';

/// Лист записи: вложения сверху, текст по линейке и действия снизу.
class RecordEditor extends StatelessWidget {
  const RecordEditor({
    super.key,
    required this.controller,
    required this.imagePaths,
    required this.audioPath,
    required this.audioDurationSeconds,
    required this.memoryDate,
    required this.isRecording,
    required this.recurrenceFrequency,
    required this.onRecurrenceTap,
    required this.onPickImage,
    required this.onRemoveImage,
    required this.onRemoveAudio,
    required this.onVoicePressed,
    required this.onChanged,
  });

  final TextEditingController controller;
  final List<String> imagePaths;
  final String? audioPath;
  final int? audioDurationSeconds;
  final DateTime memoryDate;
  final bool isRecording;
  final RecurrenceFrequency? recurrenceFrequency;
  final VoidCallback onRecurrenceTap;
  final VoidCallback onPickImage;
  final ValueChanged<String> onRemoveImage;
  final VoidCallback onRemoveAudio;
  final VoidCallback onVoicePressed;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = RecordEditorLayout.from(constraints);
        final gap = SizedBox(height: layout.gap);

        return KeyedSubtree(
          key: const ValueKey('record_editor_panel'),
          child: NotebookPageSurface(
            showLines: false,
            child: DecoratedBox(
              decoration: _paper(context),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  14,
                  10,
                  12,
                  layout.bottomPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imagePaths.isNotEmpty) ...[
                      RecordEditorImages(
                        paths: imagePaths,
                        height: layout.imageHeight,
                        maxWidth: layout.imageMaxWidth,
                        onRemove: onRemoveImage,
                      ),
                      gap,
                    ],
                    if (audioPath != null) ...[
                      _voice(context),
                      gap,
                    ] else if (isRecording) ...[
                      RecordingPill(text: AppStrings.of(context).recordingNow),
                      gap,
                    ],
                    Expanded(
                      child: RecordEditorField(
                        controller: controller,
                        onChanged: onChanged,
                      ),
                    ),
                    gap,
                    RecordEditorActions(
                      recurrenceFrequency: recurrenceFrequency,
                      isRecording: isRecording,
                      buttonSize: layout.buttonSize,
                      onRecurrenceTap: onRecurrenceTap,
                      onPickImage: onPickImage,
                      onVoicePressed: onVoicePressed,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _voice(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (details) => showMediaDeleteMenu(
        context,
        details.globalPosition,
        onDelete: onRemoveAudio,
      ),
      child: VoiceNotePlayer(
        path: audioPath!,
        recordedAt: memoryDate,
        durationSeconds: audioDurationSeconds,
      ),
    );
  }

  /// Собственный фон нужен только там, где у темы нет ни бумаги, ни текстуры.
  BoxDecoration _paper(BuildContext context) {
    final plain = NotebookVisuals.maybeOf(context) == null &&
        AppSurfaceTextures.maybeOf(context) == null;
    final colors = Theme.of(context).colorScheme;

    return BoxDecoration(
      color:
          plain ? colors.surface.withValues(alpha: 0.97) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      border: plain ? Border.all(color: colors.outlineVariant) : null,
      boxShadow: plain
          ? [
              BoxShadow(
                color: const Color(0xFF6B4F35).withValues(alpha: 0.09),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ]
          : null,
    );
  }
}
