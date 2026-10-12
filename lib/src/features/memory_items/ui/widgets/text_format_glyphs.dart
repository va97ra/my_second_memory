import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import 'text_color_picker.dart';

/// Кнопка панели оформления: вместо значка — сама буква в том виде, какой
/// она станет. Так кнопки читаются, как в Word: **Ж**, *К*, Ч, ~~аб~~.
class FormatGlyphButton extends StatelessWidget {
  const FormatGlyphButton({
    required this.label,
    required this.onTap,
    required this.child,
    this.selected = false,
    super.key,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;

  /// Оформление уже есть у выделенного — кнопка подсвечена.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const radius = BorderRadius.all(Radius.circular(10));
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: NotebookPressable(
          onTap: onTap,
          borderRadius: radius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? colors.primaryContainer : Colors.transparent,
              borderRadius: radius,
            ),
            child: DefaultTextStyle.merge(
              style: TextStyle(
                fontSize: 21,
                height: 1,
                color: selected ? colors.onPrimaryContainer : colors.onSurface,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

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

/// Буква размера: маленькая и большая рядом.
class SizeGlyph extends StatelessWidget {
  const SizeGlyph({super.key});

  @override
  Widget build(BuildContext context) => const Text.rich(
        TextSpan(children: [
          TextSpan(text: 'а', style: TextStyle(fontSize: 13)),
          TextSpan(
            text: 'А',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
          ),
        ]),
      );
}

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
