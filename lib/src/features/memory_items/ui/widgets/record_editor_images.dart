import 'package:flutter/material.dart';

import '../../../../shared/ui/media/memory_image_preview.dart';
import '../../../../shared/ui/media/memory_image_viewer.dart';
import 'media_delete_menu.dart';

/// Фотографии записи в редакторе: полоса превью, которую листают вбок.
class RecordEditorImages extends StatelessWidget {
  const RecordEditorImages({
    super.key,
    required this.paths,
    required this.height,
    required this.maxWidth,
    required this.onRemove,
  });

  final List<String> paths;
  final double height;
  final double maxWidth;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        key: const ValueKey('record_editor_images'),
        scrollDirection: Axis.horizontal,
        itemCount: paths.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) => _image(context, paths[index]),
      ),
    );
  }

  Widget _image(BuildContext context, String path) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: height),
        child: GestureDetector(
          key: ValueKey('editor_image_$path'),
          onTap: () => openMemoryImageViewer(context, path),
          onLongPressStart: (details) => showMediaDeleteMenu(
            context,
            details.globalPosition,
            onDelete: () => onRemove(path),
          ),
          child: MemoryImagePreview(
            path: path,
            fit: BoxFit.contain,
            cacheWidth: 720,
          ),
        ),
      ),
    );
  }
}
