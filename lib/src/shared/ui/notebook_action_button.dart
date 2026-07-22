import 'package:flutter/material.dart';

import '../../core/theme/notebook/notebook_visuals.dart';
import 'notebook_pressable.dart';

class NotebookActionButton extends StatelessWidget {
  const NotebookActionButton({
    required this.onPressed,
    required this.child,
    this.icon,
    super.key,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final visuals = NotebookVisuals.maybeOf(context);
    if (visuals == null) {
      if (icon == null) {
        return FilledButton(
          onPressed: onPressed,
          child: child,
        );
      }
      return FilledButton.icon(
        onPressed: onPressed,
        icon: icon!,
        label: child,
      );
    }
    final enabled = onPressed != null;
    return NotebookPressable(
      onTap: onPressed,
      pressedOffset: 3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: enabled
                ? [visuals.primaryTop, visuals.primaryBottom]
                : const [Color(0xFFD2B59C), Color(0xFFAF917A)],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFFB495), width: 1.2),
          boxShadow: !enabled
              ? const []
              : [
                  BoxShadow(
                    color: visuals.primaryShadow,
                    offset: const Offset(0, 6),
                  ),
                  const BoxShadow(
                    color: Color(0x55000000),
                    blurRadius: 7,
                    offset: Offset(0, 8),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                IconTheme.merge(
                  data: const IconThemeData(color: Colors.white, size: 20),
                  child: icon!,
                ),
                const SizedBox(width: 8),
              ],
              DefaultTextStyle.merge(
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
