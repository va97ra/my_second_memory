import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Палитра карточки темы: оттенок, яркость и прозрачность тремя полосами.
///
/// На каждом движении ручки цвет уходит в [onChanged], чтобы образцы и сама
/// тема менялись под пальцем; [onChangeEnd] — когда его отпустили.
class ThemeColorPicker extends StatefulWidget {
  const ThemeColorPicker({
    super.key,
    required this.color,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final Color color;
  final ValueChanged<Color> onChanged;
  final VoidCallback onChangeEnd;

  /// Совсем прозрачный цвет пропал бы с бумаги: нижний предел — четверть.
  static const minOpacity = 0.25;

  @override
  State<ThemeColorPicker> createState() => _ThemeColorPickerState();
}

class _ThemeColorPickerState extends State<ThemeColorPicker> {
  late ColorTone _tone;
  late double _opacity;
  Color? _lastEmitted;

  @override
  void initState() {
    super.initState();
    _read(widget.color);
  }

  @override
  void didUpdateWidget(covariant ThemeColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Свой же цвет, вернувшийся сверху, ручки не двигает: разбор цвета обратно
    // на оттенок и светлоту округляет их, и ручка уползала бы на каждом кадре.
    if (widget.color != _lastEmitted && widget.color != oldWidget.color) {
      _read(widget.color);
    }
  }

  void _read(Color color) {
    _tone = ColorTone.fromColor(color.withValues(alpha: 1));
    _opacity = color.a.clamp(ThemeColorPicker.minOpacity, 1.0);
  }

  void _emit({ColorTone? tone, double? opacity}) {
    setState(() {
      _tone = tone ?? _tone;
      _opacity = (opacity ?? _opacity).clamp(ThemeColorPicker.minOpacity, 1.0);
    });
    final color = _tone.color.withValues(alpha: _opacity);
    _lastEmitted = color;
    widget.onChanged(color);
  }

  double get _opacityPosition =>
      (_opacity - ThemeColorPicker.minOpacity) /
      (1 - ThemeColorPicker.minOpacity);

  double _opacityAt(double position) =>
      ThemeColorPicker.minOpacity +
      position.clamp(0.0, 1.0) * (1 - ThemeColorPicker.minOpacity);

  @override
  Widget build(BuildContext context) {
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    final solid = _tone.color;
    final faint = Color.alphaBlend(
      solid.withValues(alpha: ThemeColorPicker.minOpacity),
      AppPalette.paper,
    );

    Widget track(
      String key,
      String label,
      double value,
      LinearGradient gradient,
      Color thumb,
      void Function(double position) onChanged,
      double step,
    ) {
      void stepBy(double delta) {
        onChanged(value + delta);
        widget.onChangeEnd();
      }

      return Row(
        children: [
          SizedBox(
            width: 96,
            child: ExcludeSemantics(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
          Expanded(
            child: ColorGradientTrack(
              key: ValueKey('theme_color_$key'),
              semanticLabel: label,
              value: value,
              gradient: gradient,
              thumbColor: thumb,
              onChanged: onChanged,
              onChangeEnd: widget.onChangeEnd,
              onDecrease: () => stepBy(-step),
              onIncrease: () => stepBy(step),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        track(
          'hue',
          isRu ? 'Цвет' : 'Colour',
          _tone.hue / 360,
          const LinearGradient(
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
          _tone.thumbColor,
          (position) => _emit(tone: _tone.withHuePosition(position)),
          0.02,
        ),
        track(
          'brightness',
          isRu ? 'Яркость' : 'Brightness',
          _tone.tone,
          LinearGradient(
            colors: [_tone.lightestColor, _tone.vividColor, _tone.darkestColor],
            stops: const [0, 0.5, 1],
          ),
          solid,
          (position) => _emit(tone: _tone.withTonePosition(position)),
          0.04,
        ),
        track(
          'opacity',
          isRu ? 'Прозрачность' : 'Opacity',
          _opacityPosition,
          LinearGradient(colors: [faint, solid]),
          Color.alphaBlend(solid.withValues(alpha: _opacity), AppPalette.paper),
          (position) => _emit(opacity: _opacityAt(position)),
          0.05,
        ),
      ],
    );
  }
}
