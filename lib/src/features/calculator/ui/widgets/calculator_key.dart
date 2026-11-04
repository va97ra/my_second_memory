import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'calculator_key_surface.dart';

/// Чем клавиша занята.
///
/// Роль решает цвет: столбец действий должно быть видно, не читая знаков, а
/// «равно» заканчивает счёт и потому закрашено целиком, а не вполсилы.
/// Служебные клавиши, наоборот, тише цифр: акцент на клавиатуре держат только
/// действия и «равно» — так устроены и айфоновский, и гугловский, и виндовый
/// калькуляторы. Ряд памяти был закрашен как действия и перетягивал взгляд
/// сильнее самих действий. Поэтому у него своя тихая краска: цвет акцента
/// не тот и не в полную силу.
enum CalculatorKeyRole { service, memory, plain, operation, result }

class CalculatorKey extends StatefulWidget {
  const CalculatorKey({
    required this.label,
    required this.onPressed,
    this.icon,
    this.selected = false,
    this.role = CalculatorKeyRole.plain,
    super.key,
  });

  final String label;

  /// Значок вместо подписи. Нужен там, где знака нет в шрифте: `⌫` приезжал
  /// из системного набора символов и выделялся чужим рисунком среди остальных
  /// клавиш.
  final IconData? icon;
  final VoidCallback onPressed;
  final bool selected;
  final CalculatorKeyRole role;

  @override
  State<CalculatorKey> createState() => _CalculatorKeyState();
}

class _CalculatorKeyState extends State<CalculatorKey> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (baseColor, inkColor) = widget.selected
        ? (colors.secondaryContainer, colors.onSecondaryContainer)
        : switch (widget.role) {
            CalculatorKeyRole.result => (colors.primary, colors.onPrimary),
            CalculatorKeyRole.operation => (
                colors.primaryContainer,
                colors.onPrimaryContainer,
              ),
            CalculatorKeyRole.plain => (
                // На серебре клавиша цвета фона с ним сливается, на чёрной коже нет.
                colors.brightness == Brightness.light
                    ? Color.lerp(
                        colors.surfaceContainerHighest,
                        colors.onSurface,
                        0.14,
                      )!
                    : colors.surfaceContainerHighest,
                colors.onSurface,
              ),
            CalculatorKeyRole.memory => (
                Color.alphaBlend(
                  colors.tertiary.withValues(alpha: 0.28),
                  colors.surfaceContainerHighest,
                ),
                colors.onSurface,
              ),
            CalculatorKeyRole.service => (
                colors.surfaceContainer,
                colors.onSurfaceVariant,
              ),
          };
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      child: CalculatorKeySurface(
        baseColor: baseColor,
        pressed: _pressed,
        onPressed: widget.onPressed,
        onHighlightChanged: (value) => setState(() => _pressed = value),
        child: LayoutBuilder(
          builder: (context, constraints) => Center(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                // Подпись лежит под линзой экранной клавиши. Системный шрифт
                // сохраняет разборчивыми `÷` и надстрочные `ˣ ʸ ⁻`.
                child: widget.icon == null
                    ? DefaultTextStyle(
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: _labelSize(constraints),
                          color: inkColor,
                        ),
                        child: Text(widget.label, maxLines: 1),
                      )
                    : Icon(
                        widget.icon,
                        size: _labelSize(constraints),
                        color: inkColor,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Знак живёт по размеру клавиши, а не по общему размеру текста: на
  /// клавиатуре во весь экран цифра шрифта абзаца выглядит потерянной. Длинным
  /// подписям вроде «sin» этого размера не хватит, и [FittedBox] ужмёт их
  /// обратно по ширине.
  double _labelSize(BoxConstraints constraints) {
    final side = math.min(constraints.maxWidth, constraints.maxHeight);
    if (!side.isFinite) return 16;
    return (side * 0.42).clamp(16.0, 32.0);
  }
}
