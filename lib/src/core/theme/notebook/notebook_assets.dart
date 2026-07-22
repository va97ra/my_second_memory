import 'dart:async';

import 'package:flutter/material.dart';

abstract final class NotebookAssets {
  static const wood = 'assets/textures/notebook_wood.webp';
  static const paper = 'assets/textures/notebook_paper.webp';
  static const leather = 'assets/textures/notebook_leather_contrast.png';

  static Future<void> preload() async {
    await Future.wait([
      _load(const AssetImage(wood)),
      _load(const AssetImage(paper)),
      _load(const AssetImage(leather)),
    ]).timeout(const Duration(seconds: 2));
  }

  static Future<void> _load(ImageProvider provider) {
    final completer = Completer<void>();
    final stream = provider.resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (_, __) {
        stream.removeListener(listener);
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      onError: (_, __) {
        stream.removeListener(listener);
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
    );
    stream.addListener(listener);
    return completer.future;
  }
}
