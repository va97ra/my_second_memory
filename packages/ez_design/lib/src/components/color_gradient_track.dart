import 'package:flutter/material.dart';

/// Полоса-градиент с ручкой: тап и перетаскивание задают значение 0..1.
///
/// Полоса объявлена ползунком для чтения с экрана, поэтому шаг клавишами
/// приходит отдельными вызовами, а не через жест.
class ColorGradientTrack extends StatelessWidget {
  const ColorGradientTrack({
    super.key,
    required this.semanticLabel,
    required this.value,
    required this.gradient,
    required this.thumbColor,
    required this.onChanged,
    required this.onDecrease,
    required this.onIncrease,
    this.onChangeEnd,
  });

  final String semanticLabel;
  final double value;
  final LinearGradient gradient;
  final Color thumbColor;
  final ValueChanged<double> onChanged;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  /// Палец отпустили: значение окончательное и его можно сохранять.
  final VoidCallback? onChangeEnd;

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
            onTapUp: (_) => onChangeEnd?.call(),
            onHorizontalDragEnd: (_) => onChangeEnd?.call(),
            child: SizedBox(
              height: 34,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    top: 11,
                    bottom: 11,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  Positioned(
                    left: (width - 26) * value,
                    top: 4,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: thumbColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
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
