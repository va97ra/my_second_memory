import 'package:flutter/material.dart';

import 'text_color_picker.dart';

/// Буква цвета: радуга оттенков, под ней — полоска выбранного цвета.
/// Цвет не выбран — полоска тоже радужная.
class ColorGlyph extends StatelessWidget {
  const ColorGlyph({required this.color, super.key});

  final int? color;

  static final _rainbow = LinearGradient(colors: textHueRainbow);

  @override
  Widget build(BuildContext context) {
    final chosen = color;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: _rainbow.createShader,
          child: const Text(
            'А',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
          ),
        ),
        const SizedBox(height: 3),
        Container(
          width: 22,
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: chosen == null ? null : Color(0xFF000000 | chosen),
            gradient: chosen == null ? _rainbow : null,
          ),
        ),
      ],
    );
  }
}
