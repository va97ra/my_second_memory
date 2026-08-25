import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Текстура бумаги, загруженная один раз на ассет.
///
/// Загрузка асинхронная, а спрашивают текстуру на каждом перевороте: кэш
/// держит и готовую картинку, и незавершённую загрузку, чтобы один ассет не
/// читался дважды, а прежняя картинка освобождалась при смене темы.
class PaperTextureCache {
  ui.Image? _image;
  Future<ui.Image?>? _load;
  String? _asset;

  /// Загруженная текстура или null, пока её нет.
  ui.Image? get image => _image;

  /// Переключает кэш на другой ассет и забывает всё, что было загружено для
  /// прежнего. Возвращает false, если ассет тот же и трогать нечего.
  bool changeAsset(String? asset) {
    if (asset == _asset) return false;
    _image?.dispose();
    _image = null;
    _load = null;
    _asset = asset;
    return true;
  }

  Future<ui.Image?> load(BuildContext context, String? asset) {
    if (asset == null) return SynchronousFuture(null);
    if (_image != null && _asset == asset) return SynchronousFuture(_image);
    if (_load != null && _asset == asset) return _load!;

    _asset = asset;
    final completer = Completer<ui.Image?>();
    final stream = AssetImage(asset).resolve(
      createLocalImageConfiguration(context),
    );
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        stream.removeListener(listener);
        final image = info.image.clone();
        if (!context.mounted || _asset != asset) {
          image.dispose();
          if (!completer.isCompleted) completer.complete(null);
          return;
        }
        _image?.dispose();
        _image = image;
        if (!completer.isCompleted) completer.complete(image);
      },
      onError: (_, __) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete(null);
      },
    );
    stream.addListener(listener);
    _load = completer.future.whenComplete(() {
      if (_asset == asset) _load = null;
    });
    return _load!;
  }

  void dispose() {
    _image?.dispose();
    _image = null;
    _load = null;
  }
}
