import 'package:flutter/material.dart';

import 'memory_image_preview.dart';
import 'memory_image_viewer.dart';

/// Превью первой фотографии записи. Остальные считаются числом в углу.
class MemoryCardImageThumbnail extends StatelessWidget {
  const MemoryCardImageThumbnail({
    super.key,
    required this.paths,
    required this.compact,
  });

  final List<String> paths;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final path = paths.first;

    return SizedBox(
      width: compact ? 48 : 54,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('feed_image_$path'),
            onTap: () => openMemoryImageViewer(context, path),
            child: Stack(
              fit: StackFit.expand,
              children: [
                MemoryImagePreview(
                  path: path,
                  fit: BoxFit.contain,
                  cacheWidth: 720,
                ),
                if (paths.length > 1)
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        child: Text(
                          '+${paths.length - 1}',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
