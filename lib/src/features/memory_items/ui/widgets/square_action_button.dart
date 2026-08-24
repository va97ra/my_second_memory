import 'package:flutter/material.dart';
import 'package:ez_design/ez_design.dart';

/// Квадратная кнопка действия рядом с полем записи.
class SquareActionButton extends StatelessWidget {
  const SquareActionButton({super.key, 
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.size = 42,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final notebook = NotebookVisuals.maybeOf(context);
    if (notebook == null) {
      return IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          fixedSize: Size.square(size),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          foregroundColor: color,
          backgroundColor: color.withValues(alpha: 0.12),
          side: BorderSide(color: color.withValues(alpha: 0.22)),
        ),
      );
    }
    return Tooltip(
      message: tooltip,
      child: NotebookPressable(
        onTap: onPressed,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.68)),
            boxShadow: notebookSurfaceShadow(
              context,
              NotebookSurfaceDepth.tile,
            ),
          ),
          child: Icon(icon, color: color),
        ),
      ),
    );
  }
}
