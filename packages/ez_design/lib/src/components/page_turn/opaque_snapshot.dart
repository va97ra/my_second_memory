import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Снимок страницы, положенный на непрозрачную подложку: сквозь него не
/// должно просвечивать то, что осталось под ним.
class OpaqueSnapshot extends StatelessWidget {
  const OpaqueSnapshot({
    super.key,required this.image, required this.fallback});

  final ui.Image image;
  final Color fallback;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: fallback,
      child: RawImage(
        image: image,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}
