import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Буквы шрифта — выбранным шрифтом, а пока не выбран — рукописным, чтобы
/// сразу было видно, что здесь меняют начертание.
class FontGlyph extends StatelessWidget {
  const FontGlyph({required this.font, super.key});

  final String? font;

  @override
  Widget build(BuildContext context) {
    final family = font == null
        ? AppContentFontStyle.caveat.family
        : AppContentFontStyle.fromStorage(font).family;
    return Text('Аб', style: TextStyle(fontFamily: family, fontSize: 23));
  }
}
