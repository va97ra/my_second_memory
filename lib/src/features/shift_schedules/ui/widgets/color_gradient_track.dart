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
