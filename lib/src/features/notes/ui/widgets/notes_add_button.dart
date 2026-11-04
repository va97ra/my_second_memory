import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Круглый полупрозрачный плюс: новая записка.
class NotesAddButton extends StatelessWidget {
  const NotesAddButton({super.key, required this.onPressed});

  static const size = 56.0;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final label = AppStrings.of(context).newNote;

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: NotebookPressable(
          key: const ValueKey('notes_add'),
          onTap: onPressed,
          borderRadius: BorderRadius.circular(size / 2),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primary.withValues(alpha: 0.72),
            ),
            child: Icon(Icons.add_rounded, size: 32, color: colors.onPrimary),
          ),
        ),
      ),
    );
  }
}
