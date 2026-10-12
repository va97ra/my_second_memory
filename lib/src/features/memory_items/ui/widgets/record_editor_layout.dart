import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import '../../../../shared/ui/memory_card/memory_item_presentation.dart';

@immutable
class RecordEditorLayout {
  const RecordEditorLayout({
    required this.gap,
    required this.imageHeight,
    required this.imageMaxWidth,
    required this.bottomPadding,
    required this.buttonSize,
  });

  factory RecordEditorLayout.from(BoxConstraints constraints) {
    final compact = constraints.maxHeight < 360;
    final veryCompact = constraints.maxHeight < 280;
    return RecordEditorLayout(
      gap: veryCompact
          ? 6
          : compact
              ? 8
              : 12,
      imageHeight: veryCompact
          ? 72
          : compact
              ? 120
              : memoryAttachmentPreviewHeight,
      imageMaxWidth: veryCompact
          ? 120
          : compact
              ? 180
              : constraints.maxWidth.clamp(
                  0.0,
                  memoryAttachmentPreviewMaxWidth,
                ),
      bottomPadding: compact ? 8 : 12,
      buttonSize: compact ? 38 : 42,
    );
  }

  final double gap;
  final double imageHeight;
  final double imageMaxWidth;
  final double bottomPadding;
  final double buttonSize;
}

/// Бумага листа записи. Собственный фон нужен только там, где у темы нет ни
/// бумаги, ни текстуры.
BoxDecoration recordEditorPaper(BuildContext context) {
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
