import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Миниатюра темы-экрана: панель инструментов, сетка дней с отмеченным
/// сегодня и нижняя панель — то же, что видно на календаре, только мелко.
class ThemePreviewScreen extends StatelessWidget {
  const ThemePreviewScreen({super.key, required this.colors});

  final ScreenThemeColors colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color.lerp(colors.backgroundStart, colors.accent, 0.16)!,
            colors.backgroundStart,
            colors.backgroundEnd,
          ],
          stops: const [0, 0.4, 1],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          children: [
            Row(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 3),
                  Expanded(child: _panel(height: 11)),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Expanded(child: _grid()),
            const SizedBox(height: 4),
            _panel(height: 9, fill: colors.navigation, dot: true),
          ],
        ),
      ),
    );
  }

  Widget _grid() {
    return Column(
      children: [
        for (var row = 0; row < 3; row++) ...[
          if (row > 0) const SizedBox(height: 3),
          Expanded(
            child: Row(
              children: [
                for (var column = 0; column < 4; column++) ...[
                  if (column > 0) const SizedBox(width: 3),
                  Expanded(
                    child: _day(
                      today: row == 1 && column == 2,
                      capped: (row + column) % 3 == 0,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Ячейка дня: цветная шапка сверху, у сегодня — акцентная и со свечением.
  Widget _day({required bool today, required bool capped}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.tile,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: today ? colors.accent : colors.border,
          width: today ? 1 : 0.5,
        ),
        boxShadow: today
            ? [
                BoxShadow(
                  color: colors.glow.withValues(alpha: 0.55),
                  blurRadius: 4,
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          if (today || capped)
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: today ? colors.accent : colors.event,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _panel({required double height, Color? fill, bool dot = false}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: fill ?? colors.panel,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: colors.border, width: 0.5),
      ),
      child: dot
          ? Align(
              alignment: const Alignment(-0.72, 0),
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: colors.accent,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            )
          : null,
    );
  }
}
