import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

import 'gradient_slider.dart';
import 'text_color_picker.dart';

/// Два ползунка цвета выделенного текста — оттенок и насыщенность — и
/// кнопка «как у записи».
class TextColorSheet extends StatefulWidget {
  const TextColorSheet({
    super.key,
    required this.current,
    required this.onChanged,
  });

  final int? current;
  final ValueChanged<int?> onChanged;

  @override
  State<TextColorSheet> createState() => _TextColorSheetState();
}

class _TextColorSheetState extends State<TextColorSheet> {
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
