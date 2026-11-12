import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Выбор рисунка графика: `5/2`, `2/2`, сутки через трое или свой.
class ShiftPresetButton extends StatelessWidget {
  const ShiftPresetButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Semantics(
      selected: isSelected,
      child: NotebookPressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 40,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppPalette.accent
                : colors.onSurface.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          // Подпись ужимается целиком: «сутки/трое» в четверти узкого экрана.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? readableInkOn(AppPalette.accent)
                    : colors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
