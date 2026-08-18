part of '../shift_schedules_screen.dart';

class _ShiftColorPicker extends StatefulWidget {
  const _ShiftColorPicker({
    required this.color,
    required this.onChanged,
  });

  final Color color;
  final ValueChanged<Color> onChanged;

  @override
  State<_ShiftColorPicker> createState() => _ShiftColorPickerState();
}

class _ShiftColorPickerState extends State<_ShiftColorPicker> {
  static const _baseSaturation = 0.82;
  static const _baseValue = 0.92;

  late double _hue;
  late double _tone;
  late Color _currentColor;
  int? _lastEmittedColor;

  @override
  void initState() {
    super.initState();
    _syncFromColor(widget.color);
  }

  @override
  void didUpdateWidget(covariant _ShiftColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextColor = widget.color.toARGB32();
    if (nextColor != _lastEmittedColor &&
        nextColor != oldWidget.color.toARGB32()) {
      _syncFromColor(widget.color);
    }
  }

  void _syncFromColor(Color color) {
    _currentColor = color;
    final hsv = HSVColor.fromColor(color);
    _hue = hsv.saturation < 0.02 ? 0 : hsv.hue;
    if (hsv.value >= _baseValue) {
      final lightProgress =
          _unit((hsv.saturation - 0.08) / (_baseSaturation - 0.08));
      _tone = lightProgress * 0.5;
    } else {
      final darkProgress =
          _unit((_baseValue - hsv.value) / (_baseValue - 0.24));
      _tone = 0.5 + darkProgress * 0.5;
    }
  }

  Color get _vividColor =>
      HSVColor.fromAHSV(1, _hue, _baseSaturation, _baseValue).toColor();

  Color _colorAtTone(double tone) {
    if (tone <= 0.5) {
      final progress = tone * 2;
      return HSVColor.fromAHSV(
        1,
        _hue,
        _lerp(0.08, _baseSaturation, progress),
        _lerp(1, _baseValue, progress),
      ).toColor();
    }
    final progress = (tone - 0.5) * 2;
    return HSVColor.fromAHSV(
      1,
      _hue,
      _lerp(_baseSaturation, 0.92, progress),
      _lerp(_baseValue, 0.24, progress),
    ).toColor();
  }

  void _setHue(double position) {
    setState(() {
      _hue = _unit(position) * 360;
      _currentColor = _colorAtTone(_tone);
    });
    _emitColor();
  }

  void _setTone(double position) {
    setState(() {
      _tone = _unit(position);
      _currentColor = _colorAtTone(_tone);
    });
    _emitColor();
  }

  void _emitColor() {
    final color = _currentColor;
    _lastEmittedColor = color.toARGB32();
    widget.onChanged(color);
  }

  @override
  Widget build(BuildContext context) {
    final color = _currentColor;
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).languageCode;
    final isRu = locale == 'ru';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: notebookSurfaceShadow(
          context,
          NotebookSurfaceDepth.card,
        ),
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
                      color: colorScheme.onSurface.withValues(alpha: 0.28),
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
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _ColorGradientTrack(
              key: const ValueKey('shift_color_hue'),
              semanticLabel: isRu ? 'Оттенок цвета' : 'Color hue',
              value: _hue / 360,
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
              thumbColor: HSVColor.fromAHSV(1, _hue, 0.86, 0.96).toColor(),
              onChanged: _setHue,
              onDecrease: () => _setHue((_hue / 360) - 0.02),
              onIncrease: () => _setHue((_hue / 360) + 0.02),
            ),
            const SizedBox(height: 10),
            _ColorGradientTrack(
              key: const ValueKey('shift_color_tone'),
              semanticLabel: isRu ? 'Светлота цвета' : 'Color brightness',
              value: _tone,
              gradient: LinearGradient(
                colors: [
                  HSVColor.fromAHSV(1, _hue, 0.08, 1).toColor(),
                  _vividColor,
                  HSVColor.fromAHSV(1, _hue, 0.92, 0.24).toColor(),
                ],
                stops: const [0, 0.5, 1],
              ),
              thumbColor: color,
              onChanged: _setTone,
              onDecrease: () => _setTone(_tone - 0.04),
              onIncrease: () => _setTone(_tone + 0.04),
            ),
          ],
        ),
      ),
    );
  }

  static double _unit(double value) {
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }

  static double _lerp(double start, double end, double progress) =>
      start + (end - start) * progress;
}

class _ColorGradientTrack extends StatelessWidget {
  const _ColorGradientTrack({
    super.key,
    required this.semanticLabel,
    required this.value,
    required this.gradient,
    required this.thumbColor,
    required this.onChanged,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String semanticLabel;
  final double value;
  final LinearGradient gradient;
  final Color thumbColor;
  final ValueChanged<double> onChanged;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        void update(Offset localPosition) {
          onChanged(localPosition.dx / width);
        }

        return Semantics(
          label: semanticLabel,
          value: '${(value * 100).round()}%',
          decreasedValue: '${((value * 100).round() - 1).clamp(0, 100)}%',
          increasedValue: '${((value * 100).round() + 1).clamp(0, 100)}%',
          slider: true,
          onDecrease: onDecrease,
          onIncrease: onIncrease,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) => update(details.localPosition),
            onHorizontalDragStart: (details) => update(details.localPosition),
            onHorizontalDragUpdate: (details) => update(details.localPosition),
            child: SizedBox(
              height: 34,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    top: 4,
                    bottom: 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.24),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: (width - 22) * value,
                    top: 0,
                    child: Container(
                      width: 22,
                      height: 34,
                      decoration: BoxDecoration(
                        color: thumbColor,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x66000000),
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
