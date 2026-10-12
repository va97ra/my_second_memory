import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

/// Оформленный текст записи — строкой для экрана. Одна на редактор и
/// карточки: жирный, курсив, подчёркнутый, зачёркнутый, цвет, размер и
/// шрифт выглядят везде одинаково.
TextSpan styledTextSpan(StyledText text, TextStyle base) {
  if (text.isPlain) return TextSpan(text: text.plain, style: base);
  return TextSpan(
    style: base,
    children: [
      for (final run in text.runs(includePlain: true))
        TextSpan(
          text: text.plain.substring(run.start, run.end),
          style: run.mark.isPlain ? null : markStyle(run.mark, base),
        ),
    ],
  );
}

/// Как выглядит оформление поверх обычного стиля текста.
TextStyle markStyle(TextMark mark, TextStyle base) {
  final font = mark.font == null
      ? null
      : AppContentFontStyle.fromStorage(mark.font);
  final decorations = [
    if (mark.underline) TextDecoration.underline,
    if (mark.strike) TextDecoration.lineThrough,
  ];
  return TextStyle(
    fontWeight: mark.bold && (font?.hasWeights ?? true) ? FontWeight.w800 : null,
    fontStyle: mark.italic ? FontStyle.italic : null,
    decoration:
        decorations.isEmpty ? null : TextDecoration.combine(decorations),
    color: mark.color == null ? null : Color(0xFF000000 | mark.color!),
    fontSize: mark.size == null
        ? null
        : (base.fontSize ?? 14) * mark.size!.scale,
    fontFamily: font?.family,
  );
}
