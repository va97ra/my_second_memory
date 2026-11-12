import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Physical surface of one calculator key.
///
/// Notebook themes keep their raised solid key. Screen themes use a clear
/// plate: the label sits below a thick concave profile, while a short-lived
/// lamp glows from inside the plate for as long as the key is held.
class CalculatorKeySurface extends StatelessWidget {
  const CalculatorKeySurface({
    required this.baseColor,
    required this.pressed,
    required this.onPressed,
    required this.onHighlightChanged,
    required this.child,
    super.key,
  });

  final Color baseColor;
  final bool pressed;
  final VoidCallback onPressed;
  final ValueChanged<bool> onHighlightChanged;
  final Widget child;

  static const _radius = BorderRadius.all(Radius.circular(8));

  @override
  Widget build(BuildContext context) {
    final topColor = Color.alphaBlend(
      Colors.white.withValues(alpha: 0.10),
      baseColor,
    );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      transform: Matrix4.translationValues(0, pressed ? 2 : 0, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [topColor, baseColor],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: pressed ? 0.18 : 0.38),
            // Тень меньше зазора между клавишами: иначе она заливает его.
            blurRadius: pressed ? 1 : 3,
            offset: Offset(0, pressed ? 1 : 2),
          ),
        ],
        borderRadius: _radius,
      ),
      child: _ink(child),
    );
  }

  Widget _ink(Widget content) => NotebookPressable(
        onTap: onPressed,
        onHighlightChanged: onHighlightChanged,
        child: content,
      );
}
