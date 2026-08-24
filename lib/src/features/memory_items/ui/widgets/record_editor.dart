import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import '../../../../shared/ui/media/memory_image_preview.dart';
import '../../../../shared/ui/media/memory_image_viewer.dart';
import '../../../../shared/ui/media/voice_note_player.dart';
import '../../../../shared/ui/memory_card/memory_item_presentation.dart';
import 'recording_pill.dart';
import 'recurrence_badge.dart';
import 'square_action_button.dart';

/// Поле записи с кнопками фотографии, голоса и сохранения.
class RecordEditor extends StatelessWidget {
  const RecordEditor({super.key, 
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
    final strings = AppStrings.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 360;
        final imageHeight = compact ? 120.0 : memoryAttachmentPreviewHeight;
        final imageMaxWidth = compact
            ? 180.0
            : constraints.maxWidth.clamp(
                0.0,
                memoryAttachmentPreviewMaxWidth,
              );
        final buttonSize = compact ? 38.0 : 42.0;
        final notebook = NotebookVisuals.maybeOf(context);
        final textures = AppSurfaceTextures.maybeOf(context);
        final typography = AppContentTypography.of(context);
        final recordTextStyle = typography.apply(
          Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
          manropeWeight: FontWeight.w600,
        );
        final recordLineHeight = typography.measuredLineHeight(recordTextStyle);

        return KeyedSubtree(
          key: const ValueKey('record_editor_panel'),
          child: NotebookPageSurface(
            showLines: false,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: notebook == null && textures == null
                    ? Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.97)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: notebook == null && textures == null
                    ? Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      )
                    : null,
                boxShadow: notebook == null && textures == null
                    ? [
                        BoxShadow(
                          color:
                              const Color(0xFF6B4F35).withValues(alpha: 0.09),
                          blurRadius: 18,
                          offset: const Offset(0, 7),
                        ),
                      ]
                    : null,
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(14, 10, 12, compact ? 8 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imagePaths.isNotEmpty) ...[
                      SizedBox(
                        height: imageHeight,
                        child: ListView.separated(
                          key: const ValueKey('record_editor_images'),
                          scrollDirection: Axis.horizontal,
                          itemCount: imagePaths.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final path = imagePaths[index];
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: imageMaxWidth,
                                      maxHeight: imageHeight,
                                    ),
                                    child: GestureDetector(
                                      key: ValueKey('editor_image_$path'),
                                      onTap: () =>
                                          openMemoryImageViewer(context, path),
                                      onLongPressStart: (details) =>
                                          _showMediaDeleteMenu(
                                        context,
                                        details.globalPosition,
                                        onDelete: () => onRemoveImage(path),
                                      ),
                                      child: MemoryImagePreview(
                                        path: path,
                                        fit: BoxFit.contain,
                                        cacheWidth: 720,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      SizedBox(height: compact ? 8 : 12),
                    ],
                    if (audioPath != null) ...[
                      GestureDetector(
                        onLongPressStart: (details) => _showMediaDeleteMenu(
                          context,
                          details.globalPosition,
                          onDelete: onRemoveAudio,
                        ),
                        child: VoiceNotePlayer(
                          path: audioPath!,
                          recordedAt: memoryDate,
                          durationSeconds: audioDurationSeconds,
                        ),
                      ),
                      SizedBox(height: compact ? 8 : 12),
                    ] else if (isRecording) ...[
                      RecordingPill(text: strings.recordingNow),
                      SizedBox(height: compact ? 8 : 12),
                    ],
                    Expanded(
                      child: CustomPaint(
                        painter: notebook == null && textures == null
                            ? null
                            : NotebookPaperLinesPainter(
                                color: notebook?.line ?? textures!.lineColor,
                                // The first rule underlines the first content
                                // row; the floating label sits above it.
                                top: recordLineHeight + 10,
                                lineHeight: recordLineHeight,
                              ),
                        child: TextFormField(
                          key: const ValueKey('record_editor_text'),
                          controller: controller,
                          expands: true,
                          maxLines: null,
                          minLines: null,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          textAlignVertical: TextAlignVertical.top,
                          scrollPadding: const EdgeInsets.only(bottom: 120),
                          style: recordTextStyle,
                          decoration: InputDecoration(
                            labelText: strings.description,
                            alignLabelWithHint: true,
                            labelStyle: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            filled: notebook == null && textures == null,
                          ),
                          onChanged: (_) => onChanged(),
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 8 : 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final badge = recurrenceFrequency == null
                            ? null
                            : RecurrenceBadge(
                                frequency: recurrenceFrequency!,
                                onTap: onRecurrenceTap,
                              );
                        final actions = Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SquareActionButton(
                              tooltip: strings.addImage,
                              icon: Icons.photo_camera_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: buttonSize,
                              onPressed: onPickImage,
                            ),
                            const SizedBox(width: 8),
                            SquareActionButton(
                              tooltip: isRecording
                                  ? strings.stopRecording
                                  : strings.voice,
                              icon: isRecording
                                  ? Icons.stop_rounded
                                  : Icons.mic_rounded,
                              color: isRecording
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).colorScheme.secondary,
                              size: buttonSize,
                              onPressed: onVoicePressed,
                            ),
                          ],
                        );
                        final stack = badge != null &&
                            (constraints.maxWidth < 230 ||
                                MediaQuery.textScalerOf(context).scale(1) >
                                    1.5);
                        if (stack) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Align(
                                  alignment: Alignment.centerLeft,
                                  child: badge),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: actions,
                              ),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            if (badge != null) badge,
                            const Spacer(),
                            actions,
                          ],
                        );
                      },
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
}

Future<void> _showMediaDeleteMenu(
  BuildContext context,
  Offset position, {
  required VoidCallback onDelete,
}) async {
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  final selected = await showMenu<bool>(
    context: context,
    position: RelativeRect.fromRect(
      Rect.fromLTWH(position.dx, position.dy, 1, 1),
      Offset.zero & overlay.size,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    items: [
      PopupMenuItem<bool>(
        value: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_rounded,
                color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 10),
            Text(
              AppStrings.of(context).delete,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ),
      ),
    ],
  );
  if (selected == true && context.mounted) onDelete();
}
