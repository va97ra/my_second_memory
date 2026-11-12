import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Плоская кнопка со значком: в строке карточки мелкая и на всю высоту строки,
/// в поле открытого аккаунта крупнее.
class AccountRowButton extends StatelessWidget {
  const AccountRowButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  })  : width = rowWidth,
        height = double.infinity,
        iconSize = 15;

  /// Кнопка в поле открытого аккаунта.
  const AccountRowButton.inField({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  })  : width = 44,
        height = 48,
        iconSize = 20;

  static const rowWidth = 36.0;

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final double width;
  final double height;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: NotebookPressable(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: width,
          height: height,
          child: Icon(
            icon,
            size: iconSize,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
