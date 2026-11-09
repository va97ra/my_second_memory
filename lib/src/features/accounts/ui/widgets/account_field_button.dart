import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Плоский значок внутри поля открытого аккаунта: рамки поля не перекрывает.
class AccountFieldButton extends StatelessWidget {
  const AccountFieldButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: NotebookPressable(
        onTap: onPressed,
        child: SizedBox(
          width: 44,
          height: 48,
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
