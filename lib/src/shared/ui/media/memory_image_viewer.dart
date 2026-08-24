import 'package:flutter/material.dart';

import 'memory_image_viewer_screen.dart';

Future<void> openMemoryImageViewer(BuildContext context, String path) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (context, animation, secondaryAnimation) {
        return MemoryImageViewer(path: path);
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}
