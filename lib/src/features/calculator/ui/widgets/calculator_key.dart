import 'dart:math' as math;

import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import 'calculator_key_surface.dart';

/// Чем клавиша занята.
///
/// Роль решает цвет: столбец действий должно быть видно, не читая знаков, а
/// «равно» заканчивает счёт и потому закрашено целиком, а не вполсилы.
/// Служебные клавиши, наоборот, тише цифр: акцент на клавиатуре держат только
/// действия и «равно» — так устроены и айфоновский, и гугловский, и виндовый
/// калькуляторы. Ряд памяти был закрашен как действия и перетягивал взгляд
/// сильнее самих действий.
enum CalculatorKeyRole { service, plain, operation, result }

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
                colors.surfaceContainerHighest,
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
        glassOpacity: _glassOpacity,
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
                          shadows: ScreenVisuals.maybeOf(context) == null
                              ? null
                              : [
                                  Shadow(
                                    color: Colors.white.withValues(alpha: 0.32),
                                    offset: const Offset(0, 0.7),
                                  ),
                                ],
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

  double get _glassOpacity => widget.selected
      ? 0.58
      : switch (widget.role) {
          CalculatorKeyRole.service => 0.20,
          CalculatorKeyRole.plain => 0.28,
          CalculatorKeyRole.operation => 0.52,
          CalculatorKeyRole.result => 0.70,
        };

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
