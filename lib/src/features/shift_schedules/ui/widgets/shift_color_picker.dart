import 'package:flutter/material.dart';

import '../../state/shift_color_tone.dart';
import 'color_gradient_track.dart';

/// Выбор цвета графика: оттенок и светлота двумя полосами.
class ShiftColorPicker extends StatefulWidget {
  const ShiftColorPicker({
    super.key,
    required this.color,
    required this.onChanged,
  });

  final Color color;
  final ValueChanged<Color> onChanged;

  @override
  State<ShiftColorPicker> createState() => _ShiftColorPickerState();
}

class _ShiftColorPickerState extends State<ShiftColorPicker> {
  late ShiftColorTone _tone;
  int? _lastEmittedColor;

  @override
  void initState() {
    super.initState();
    _tone = ShiftColorTone.fromColor(widget.color);
  }

  @override
  void didUpdateWidget(covariant ShiftColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Свой же цвет, вернувшийся сверху, ручки не двигает: разбор цвета обратно
    // на оттенок и светлоту округляет их, и ручка уползала бы на каждом кадре.
    final nextColor = widget.color.toARGB32();
    if (nextColor != _lastEmittedColor &&
        nextColor != oldWidget.color.toARGB32()) {
      _tone = ShiftColorTone.fromColor(widget.color);
    }
  }

  void _emit(ShiftColorTone tone) {
    setState(() => _tone = tone);
    _lastEmittedColor = tone.color.toARGB32();
    widget.onChanged(tone.color);
  }

  @override
  Widget build(BuildContext context) {
    final isRu = Localizations.localeOf(context).languageCode == 'ru';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ColorGradientTrack(
          key: const ValueKey('shift_color_hue'),
          semanticLabel: isRu ? 'Оттенок цвета' : 'Color hue',
          value: _tone.hue / 360,
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFF3333),
              Color(0xFFFFFF33),
              Color(0xFF33FF33),
              Color(0xFF33FFFF),
              Color(0xFF3333FF),
              Color(0xFFFF33FF),
              Color(0xFFFF3333),
            ],
          ),
          thumbColor: _tone.thumbColor,
          onChanged: (position) => _emit(_tone.withHuePosition(position)),
          onDecrease: () =>
              _emit(_tone.withHuePosition((_tone.hue / 360) - 0.02)),
          onIncrease: () =>
              _emit(_tone.withHuePosition((_tone.hue / 360) + 0.02)),
        ),
        const SizedBox(height: 4),
        ColorGradientTrack(
          key: const ValueKey('shift_color_tone'),
          semanticLabel: isRu ? 'Светлота цвета' : 'Color brightness',
          value: _tone.tone,
          gradient: LinearGradient(
            colors: [
              _tone.lightestColor,
              _tone.vividColor,
              _tone.darkestColor,
            ],
            stops: const [0, 0.5, 1],
          ),
          thumbColor: _tone.color,
          onChanged: (position) => _emit(_tone.withTonePosition(position)),
          onDecrease: () => _emit(_tone.withTonePosition(_tone.tone - 0.04)),
          onIncrease: () => _emit(_tone.withTonePosition(_tone.tone + 0.04)),
        ),
      ],
    );
  }
}
