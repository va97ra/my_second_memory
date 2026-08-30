import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Чем клавиша занята.
///
/// Роль решает цвет: столбец действий должно быть видно, не читая знаков, а
/// «равно» заканчивает счёт и потому закрашено целиком, а не вполсилы.
enum CalculatorKeyRole { plain, operation, result }

class CalculatorKey extends StatefulWidget {
  const CalculatorKey({
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.role = CalculatorKeyRole.plain,
    super.key,
  });

  final String label;
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
          };
    final topColor = Color.alphaBlend(
      Colors.white.withValues(alpha: 0.10),
      baseColor,
    );
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: Matrix4.translationValues(0, _pressed ? 2 : 0, 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [topColor, baseColor],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _pressed ? 0.18 : 0.38),
              blurRadius: _pressed ? 2 : 5,
              offset: Offset(0, _pressed ? 1 : 4),
            ),
          ],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onPressed,
            onHighlightChanged: (value) => setState(() => _pressed = value),
            child: LayoutBuilder(
              builder: (context, constraints) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: _labelSize(constraints),
                            color: inkColor,
                          ),
                    ),
                  ),
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
