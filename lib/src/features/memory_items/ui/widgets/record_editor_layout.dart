import 'package:flutter/widgets.dart';

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
