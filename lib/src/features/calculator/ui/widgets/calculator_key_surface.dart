import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Physical surface of one calculator key.
///
/// Notebook themes keep their raised solid key with a visible side. Screen
/// themes use a clear plate: the label sits below a thick concave profile,
/// while a short-lived lamp glows from inside the plate for as long as the
/// key is held.
class CalculatorKeySurface extends StatelessWidget {
  const CalculatorKeySurface({
    required this.baseColor,
    required this.glassOpacity,
    required this.pressed,
    required this.onPressed,
    required this.onHighlightChanged,
    required this.child,
    super.key,
  });

  final Color baseColor;
  final double glassOpacity;
  final bool pressed;
  final VoidCallback onPressed;
  final ValueChanged<bool> onHighlightChanged;
  final Widget child;

  static const _radius = BorderRadius.all(Radius.circular(8));

  @override
  Widget build(BuildContext context) {
    final screen = ScreenVisuals.maybeOf(context)?.colors;
    return screen == null ? _notebookSurface() : _glassSurface();
  }

  /// Ход клавиши: столько видно её бока снизу, и на столько она уходит
  /// под пальцем. Без бока клавиша читалась нарисованной плашкой.
  static const _travel = 4.0;

  Widget _notebookSurface() {
    final top =
        Color.alphaBlend(Colors.white.withValues(alpha: 0.16), baseColor);
    final bottom =
        Color.alphaBlend(Colors.black.withValues(alpha: 0.08), baseColor);
    final side =
        Color.alphaBlend(Colors.black.withValues(alpha: 0.45), baseColor);
    // Бок клавиши и её тень на столе — снаружи; лицо с подписью сверху и
    // опускается на бок, пока клавишу держат.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: side,
        borderRadius: _radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AnimatedContainer(
        key: const ValueKey('calculator_key_face'),
        duration: const Duration(milliseconds: 70),
        curve: Curves.easeOut,
        margin: pressed
            ? const EdgeInsets.only(top: _travel - 1, bottom: 1)
            : const EdgeInsets.only(bottom: _travel),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [top, bottom],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          borderRadius: _radius,
        ),
        child: _ink(child),
      ),
    );
  }

  Widget _glassSurface() {
    return ScreenGlassButton(
      key: const ValueKey('calculator_key_glass'),
      opacity: glassOpacity,
      tint: baseColor,
      onPressed: onPressed,
      onHighlightChanged: onHighlightChanged,
      painterKey: const ValueKey('calculator_key_lens'),
      lampKey: const ValueKey('calculator_key_lamp'),
      child: child,
    );
  }

  Widget _ink(Widget content) => Material(
        color: Colors.transparent,
        borderRadius: _radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          onHighlightChanged: onHighlightChanged,
          child: content,
        ),
      );
}
