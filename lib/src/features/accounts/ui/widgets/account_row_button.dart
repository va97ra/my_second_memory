import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Маленькая кнопка в строке карточки: значок мелкий, нажимается вся высота строки.
class AccountRowButton extends StatelessWidget {
  const AccountRowButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  static const width = 36.0;
  static const _iconSize = 15.0;

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: NotebookPressable(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: width,
          height: double.infinity,
          child: Icon(
            icon,
            size: _iconSize,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
