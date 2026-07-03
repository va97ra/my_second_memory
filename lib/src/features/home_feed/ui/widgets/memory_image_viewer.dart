import 'package:flutter/material.dart';

import 'memory_image_preview.dart';

Future<void> openMemoryImageViewer(BuildContext context, String path) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (context, animation, secondaryAnimation) {
        return _MemoryImageViewer(path: path);
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}

class _MemoryImageViewer extends StatelessWidget {
  const _MemoryImageViewer({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('memory_image_viewer'),
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          key: const ValueKey('memory_image_viewer_close'),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: constraints.maxWidth - 24,
                    height: constraints.maxHeight - 24,
                    child: MemoryImagePreview(
                      key: const ValueKey('memory_image_viewer_image'),
                      path: path,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
