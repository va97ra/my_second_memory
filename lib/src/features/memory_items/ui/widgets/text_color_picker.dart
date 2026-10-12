import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

import 'gradient_slider.dart';

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
    builder: (_) => _TextColorSheet(current: current, onChanged: onChanged),
  );
}

class _TextColorSheet extends StatefulWidget {
  const _TextColorSheet({required this.current, required this.onChanged});

  final int? current;
  final ValueChanged<int?> onChanged;

  @override
  State<_TextColorSheet> createState() => _TextColorSheetState();
}

class _TextColorSheetState extends State<_TextColorSheet> {
  late double _hue;
  late double _saturation;
  late int? _color = widget.current;

  @override
  void initState() {
    super.initState();
    final current = widget.current;
    final hsl = current == null
        ? null
        : HSLColor.fromColor(Color(0xFF000000 | current));
    _hue = hsl?.hue ?? 0;
    _saturation = hsl?.saturation ?? 0.85;
  }

  void _set({double? hue, double? saturation}) {
    setState(() {
      _hue = hue ?? _hue;
      _saturation = saturation ?? _saturation;
      _color = textColorOf(_hue, _saturation);
    });
    widget.onChanged(_color);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = Theme.of(context).colorScheme;
    final shown =
        _color == null ? colors.onSurface : Color(0xFF000000 | _color!);
    final vivid = Color(0xFF000000 | textColorOf(_hue, 1));
    final gray = Color(0xFF000000 | textColorOf(_hue, 0));
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Аа Бб',
              style: TextStyle(
                  color: shown, fontSize: 34, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            GradientSlider(
              key: const ValueKey('format_hue'),
              label: strings.formatHue,
              value: _hue / 360,
              colors: textHueRainbow,
              thumb: vivid,
              onChanged: (value) => _set(hue: value * 360),
            ),
            GradientSlider(
              key: const ValueKey('format_saturation'),
              label: strings.formatSaturation,
              value: _saturation,
              colors: [gray, vivid],
              thumb: shown,
              onChanged: (value) => _set(saturation: value),
            ),
            TextButton(
              key: const ValueKey('format_color_default'),
              onPressed: () {
                setState(() => _color = null);
                widget.onChanged(null);
              },
              child: Text(strings.formatDefault),
            ),
          ],
        ),
      ),
    );
  }
}
