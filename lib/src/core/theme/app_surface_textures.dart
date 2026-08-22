import 'dart:async';

import 'package:flutter/material.dart';

abstract final class LightThemeAssets {
  static const wood = 'assets/textures/light_wood.webp';
  static const paper = 'assets/textures/light_paper.webp';
  static const leather = 'assets/textures/light_leather.webp';

  static Future<void> preload() async {
    await Future.wait([
      _loadTexture(const AssetImage(wood)),
      _loadTexture(const AssetImage(paper)),
      _loadTexture(const AssetImage(leather)),
    ]).timeout(const Duration(seconds: 2));
  }
}

abstract final class DarkThemeAssets {
  static const wood = 'assets/textures/dark_wood.webp';
  static const paper = 'assets/textures/dark_paper.webp';
  static const leather = 'assets/textures/dark_leather.webp';

  static Future<void> preload() async {
    await Future.wait([
      _loadTexture(const AssetImage(wood)),
      _loadTexture(const AssetImage(paper)),
      _loadTexture(const AssetImage(leather)),
    ]).timeout(const Duration(seconds: 2));
  }
}

Future<void> _loadTexture(ImageProvider provider) {
  final completer = Completer<void>();
  final stream = provider.resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (_, __) {
      stream.removeListener(listener);
      if (!completer.isCompleted) completer.complete();
    },
    onError: (_, __) {
      stream.removeListener(listener);
      if (!completer.isCompleted) completer.complete();
    },
  );
  stream.addListener(listener);
  return completer.future;
}

@immutable
class AppSurfaceTextures extends ThemeExtension<AppSurfaceTextures> {
  const AppSurfaceTextures({
    required this.backgroundAsset,
    required this.surfaceAsset,
    required this.accentAsset,
    required this.lineColor,
    required this.backgroundOpacity,
    required this.surfaceOpacity,
    required this.accentOpacity,
  });

  static const light = AppSurfaceTextures(
    backgroundAsset: LightThemeAssets.wood,
    surfaceAsset: LightThemeAssets.paper,
    accentAsset: LightThemeAssets.leather,
    lineColor: Color(0x3D6B5D47),
    backgroundOpacity: 0.22,
    surfaceOpacity: 0.45,
    accentOpacity: 0.4,
  );

  static const dark = AppSurfaceTextures(
    backgroundAsset: DarkThemeAssets.wood,
    surfaceAsset: DarkThemeAssets.paper,
    accentAsset: DarkThemeAssets.leather,
    lineColor: Color(0x526F8294),
    backgroundOpacity: 0.9,
    surfaceOpacity: 0.78,
    accentOpacity: 0.36,
  );

  final String backgroundAsset;
  final String surfaceAsset;
  final String accentAsset;
  final Color lineColor;
  final double backgroundOpacity;
  final double surfaceOpacity;
  final double accentOpacity;

  static AppSurfaceTextures? maybeOf(BuildContext context) {
    return Theme.of(context).extension<AppSurfaceTextures>();
  }

  @override
  AppSurfaceTextures copyWith({
    String? backgroundAsset,
    String? surfaceAsset,
    String? accentAsset,
    Color? lineColor,
    double? backgroundOpacity,
    double? surfaceOpacity,
    double? accentOpacity,
  }) {
    return AppSurfaceTextures(
      backgroundAsset: backgroundAsset ?? this.backgroundAsset,
      surfaceAsset: surfaceAsset ?? this.surfaceAsset,
      accentAsset: accentAsset ?? this.accentAsset,
      lineColor: lineColor ?? this.lineColor,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      surfaceOpacity: surfaceOpacity ?? this.surfaceOpacity,
      accentOpacity: accentOpacity ?? this.accentOpacity,
    );
  }

  @override
  AppSurfaceTextures lerp(
    covariant AppSurfaceTextures? other,
    double t,
  ) {
    if (other == null) return this;
    return AppSurfaceTextures(
      backgroundAsset: t < 0.5 ? backgroundAsset : other.backgroundAsset,
      surfaceAsset: t < 0.5 ? surfaceAsset : other.surfaceAsset,
      accentAsset: t < 0.5 ? accentAsset : other.accentAsset,
      lineColor: Color.lerp(lineColor, other.lineColor, t)!,
      backgroundOpacity:
          _lerpDouble(backgroundOpacity, other.backgroundOpacity, t),
      surfaceOpacity: _lerpDouble(surfaceOpacity, other.surfaceOpacity, t),
      accentOpacity: _lerpDouble(accentOpacity, other.accentOpacity, t),
    );
  }
}

double _lerpDouble(double start, double end, double t) {
  return start + (end - start) * t;
}
