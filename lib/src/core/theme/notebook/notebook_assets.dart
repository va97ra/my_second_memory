import 'dart:async';

import 'package:flutter/material.dart';

abstract final class NotebookAssets {
  static const wood = 'assets/textures/notebook_wood.webp';

  /// Grain amplified from light_paper.webp: the original varies by three
  /// luminance levels out of 255, which is below what the eye picks up once it
  /// is laid down at half opacity on cream.
  static const paper = 'assets/textures/notebook_paper_grain.webp';
  static const leather = 'assets/textures/notebook_leather_contrast.png';

  /// The same notebook under a different light.
  static const darkPaper = 'assets/textures/dark_paper.webp';
  static const darkLeather = 'assets/textures/dark_leather.webp';
  static const darkWood = 'assets/textures/dark_wood.webp';

  /// Decodes only the two textures required to paint the first visible frame.
  static Future<void> preloadCurrent({required bool dark}) async {
    await Future.wait([
      _load(AssetImage(dark ? darkPaper : paper)),
      _load(AssetImage(dark ? darkLeather : leather)),
    ]).timeout(const Duration(seconds: 2));
  }

  /// Warms theme-picker and alternate-theme textures after the first frame.
  static Future<void> preloadDeferred({required bool currentIsDark}) async {
    await Future.wait([
      _load(const AssetImage(wood)),
      _load(const AssetImage(darkWood)),
      _load(AssetImage(currentIsDark ? paper : darkPaper)),
      _load(AssetImage(currentIsDark ? leather : darkLeather)),
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
