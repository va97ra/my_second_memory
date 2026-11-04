import 'dart:async';

import 'package:flutter/material.dart';

import '../../tokens/app_textures.dart';

abstract final class NotebookAssets {
  /// Светлая тема — серебристая кожа и под страницей, и на панелях.
  static const lightPage = AppTextures.silverLeather;
  static const lightLeather = AppTextures.silverLeather;

  /// Зерно бумаги: карточки и дни в обеих темах.
  static const paper = AppTextures.paperGrain;

  /// Тёмная тема — чёрная кожа и под страницей, и на панелях.
  static const darkPaper = AppTextures.blackLeather;
  static const darkLeather = AppTextures.blackLeather;

  /// Decodes only the two textures required to paint the first visible frame.
  static Future<void> preloadCurrent({required bool dark}) async {
    await Future.wait([
      _load(AssetImage(dark ? darkLeather : lightLeather)),
      _load(const AssetImage(paper)),
    ]).timeout(const Duration(seconds: 2));
  }

  /// Warms theme-picker and alternate-theme textures after the first frame.
  static Future<void> preloadDeferred({required bool currentIsDark}) async {
    await Future.wait([
      _load(AssetImage(currentIsDark ? lightLeather : darkLeather)),
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
