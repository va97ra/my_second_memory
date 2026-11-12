import 'package:flutter/material.dart';

import 'text_color_sheet.dart';

/// Светлота цвета текста постоянная: такой текст читается и на светлой
/// бумаге, и на тёмной теме. Владелец выбирает только оттенок и
/// насыщенность (решение 11 октября 2026: «просто ползунок палитры и
/// ползунок насыщенности»).
const _lightness = 0.48;

/// Цвет текста 0xRRGGBB по оттенку (0–360) и насыщенности (0–1).
int textColorOf(double hue, double saturation) =>
    HSLColor.fromAHSL(1, hue % 360, saturation, _lightness)
        .toColor()
        .toARGB32() &
    0xFFFFFF;

/// Радуга оттенков — дорожка ползунка и буква на кнопке цвета.
final textHueRainbow = [
  for (var hue = 0; hue <= 360; hue += 60)
    Color(0xFF000000 | textColorOf(hue.toDouble(), 0.85)),
];

/// Цвет выделенного текста двумя ползунками. Цвет меняется в тексте сразу,
/// пока ползунок движется: [onChanged] зовётся на каждом шаге, null — цвет
/// как у записи.
Future<void> pickTextColor(
  BuildContext context, {
  required int? current,
  required ValueChanged<int?> onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (_) => TextColorSheet(current: current, onChanged: onChanged),
  );
}
