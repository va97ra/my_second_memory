import 'package:flutter/material.dart';

import '../../../../shared/ui/media/memory_image_preview.dart';
import '../../../../shared/ui/media/memory_image_viewer.dart';

/// Фотография в безопасном просмотре: открывается во весь экран, но не
/// удаляется.
class ReadonlyImage extends StatelessWidget {
  const ReadonlyImage({
    super.key,
    required this.path,
    required this.cacheWidth,
  });

  final String path;
  final int cacheWidth;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('readonly_image_$path'),
        onTap: () => openMemoryImageViewer(context, path),
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: MemoryImagePreview(
              path: path,
              fit: BoxFit.contain,
              cacheWidth: cacheWidth,
            ),
          ),
        ),
      ),
    );
  }
}
