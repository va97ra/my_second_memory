import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../shared/ui/media/memory_image_preview.dart';
import '../../../../shared/ui/media/memory_image_viewer.dart';
import 'media_delete_menu.dart';

/// Фотографии записи в редакторе: полоса превью, которую листают вбок.
///
/// На настольной системе полоса не двигалась вовсе: мышь по умолчанию не
/// тащит прокрутку, а колесо даёт вертикальную дельту, которую горизонтальный
/// список не читает. Четвёртая фотография оказывалась за краем без всякого
/// способа до неё добраться. Поэтому здесь разрешено и то, и другое.
class RecordEditorImages extends StatefulWidget {
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
  State<RecordEditorImages> createState() => _RecordEditorImagesState();
}

class _RecordEditorImagesState extends State<RecordEditorImages> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Колесо мыши крутит вертикально, полоса едет вбок: дельту нужно перенести
  /// на другую ось руками.
  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_controller.hasClients) return;
    final delta = event.scrollDelta.dy != 0
        ? event.scrollDelta.dy
        : event.scrollDelta.dx;
    if (delta == 0) return;
    _controller.jumpTo(
      (_controller.offset + delta)
          .clamp(0.0, _controller.position.maxScrollExtent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Listener(
        onPointerSignal: _onPointerSignal,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: const {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.stylus,
              PointerDeviceKind.trackpad,
            },
          ),
          child: ListView.separated(
            key: const ValueKey('record_editor_images'),
            controller: _controller,
            scrollDirection: Axis.horizontal,
            itemCount: widget.paths.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) => _image(context, widget.paths[index]),
          ),
        ),
      ),
    );
  }

  Widget _image(BuildContext context, String path) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        // Минимум по ширине — это цель для пальца. Без него не успевшая
        // декодироваться фотография занимает нулевую ширину, и нажать по
        // ней нечем.
        constraints: BoxConstraints(
          minWidth: 56,
          maxWidth: widget.maxWidth,
          maxHeight: widget.height,
        ),
        child: GestureDetector(
          key: ValueKey('editor_image_$path'),
          onTap: () => openMemoryImageViewer(context, path),
          onLongPressStart: (details) => showMediaDeleteMenu(
            context,
            details.globalPosition,
            onDelete: () => widget.onRemove(path),
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
