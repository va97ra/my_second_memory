import 'package:flutter/material.dart';

import '../../../../shared/ui/memory_card/memory_item_presentation.dart';
import 'readonly_image.dart';

/// Фотографии записи в безопасном просмотре.
class ReadonlyImageGrid extends StatelessWidget {
  const ReadonlyImageGrid({super.key, required this.paths});

  final List<String> paths;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth < memoryAttachmentPreviewMaxWidth
            ? constraints.maxWidth
            : memoryAttachmentPreviewMaxWidth;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final path in paths)
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  maxHeight: memoryAttachmentPreviewHeight,
                ),
                child: ReadonlyImage(path: path, cacheWidth: 720),
              ),
          ],
        );
      },
    );
  }
}
