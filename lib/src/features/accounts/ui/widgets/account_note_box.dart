import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Заметка аккаунта под его полями.
class AccountNoteBox extends StatelessWidget {
  const AccountNoteBox({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        // Вырез в стекле гасит фон под собой, а не заливается своим цветом.
        color: ScreenVisuals.maybeOf(context) == null
            ? colors.surfaceContainerHighest
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: SizedBox(
          width: double.infinity,
          child: Text(text, maxLines: 4, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}
