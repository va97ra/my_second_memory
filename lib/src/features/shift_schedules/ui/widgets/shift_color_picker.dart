import 'package:ez_design/ez_design.dart';
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
    final color = _tone.color;
    final colors = Theme.of(context).colorScheme;
    final isRu = Localizations.localeOf(context).languageCode == 'ru';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: notebookSurfaceShadow(context, NotebookSurfaceDepth.card),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AnimatedContainer(
                  key: const ValueKey('shift_color_preview'),
                  duration: const Duration(milliseconds: 120),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors.onSurface.withValues(alpha: 0.28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.32),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isRu ? 'Выбранный цвет' : 'Selected color',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
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
            const SizedBox(height: 10),
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
              thumbColor: color,
              onChanged: (position) => _emit(_tone.withTonePosition(position)),
              onDecrease: () => _emit(_tone.withTonePosition(_tone.tone - 0.04)),
              onIncrease: () => _emit(_tone.withTonePosition(_tone.tone + 0.04)),
            ),
          ],
        ),
      ),
    );
  }
}
