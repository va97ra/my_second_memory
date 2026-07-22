part of '../memory_item_detail_screen.dart';

class _RecordEditor extends StatelessWidget {
  const _RecordEditor({
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
                color: notebook == null
                    ? Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.97)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: notebook == null
                    ? Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      )
                    : null,
                boxShadow: notebook == null
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
                      _RecordingPill(text: strings.recordingNow),
                      SizedBox(height: compact ? 8 : 12),
                    ],
                    Expanded(
                      child: CustomPaint(
                        painter: notebook == null
                            ? null
                            : NotebookPaperLinesPainter(
                                color: notebook.line,
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
                            filled: notebook == null,
                          ),
                          onChanged: (_) => onChanged(),
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 8 : 12),
                    Row(
                      children: [
                        if (recurrenceFrequency != null)
                          _RecurrenceBadge(
                            frequency: recurrenceFrequency!,
                            onTap: onRecurrenceTap,
                          ),
                        const Spacer(),
                        _SquareActionButton(
                          tooltip: strings.addImage,
                          icon: Icons.photo_camera_outlined,
                          color: Theme.of(context).colorScheme.primary,
                          size: buttonSize,
                          onPressed: onPickImage,
                        ),
                        const SizedBox(width: 8),
                        _SquareActionButton(
                          tooltip: isRecording
                              ? strings.stopRecording
                              : strings.voice,
                          icon: isRecording ? Icons.stop : Icons.mic_none,
                          color: isRecording
                              ? const Color(0xFFDC2626)
                              : const Color(0xFFDB2777),
                          size: buttonSize,
                          onPressed: onVoicePressed,
                        ),
                      ],
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
            Icon(Icons.delete_outline,
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

class _RecordingPill extends StatelessWidget {
  const _RecordingPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.error),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.fiber_manual_record,
              size: 12,
              color: Color(0xFFDC2626),
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF991B1B),
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SquareActionButton extends StatelessWidget {
  const _SquareActionButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.size = 42,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final notebook = NotebookVisuals.maybeOf(context);
    if (notebook == null) {
      return IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          fixedSize: Size.square(size),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          foregroundColor: color,
          backgroundColor: color.withValues(alpha: 0.12),
          side: BorderSide(color: color.withValues(alpha: 0.22)),
        ),
      );
    }
    return Tooltip(
      message: tooltip,
      child: NotebookPressable(
        onTap: onPressed,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.68)),
            boxShadow: notebookSurfaceShadow(
              context,
              NotebookSurfaceDepth.tile,
            ),
          ),
          child: Icon(icon, color: color),
        ),
      ),
    );
  }
}
