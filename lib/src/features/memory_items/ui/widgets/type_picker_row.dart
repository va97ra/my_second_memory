import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import '../../../../shared/ui/memory_card/memory_item_presentation.dart';
import 'package:ez_design/ez_design.dart';

/// Выбор вида записи.
class TypePickerRow extends StatelessWidget {
  const TypePickerRow({super.key, 
    required this.type,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final MemoryType type;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = memoryTypeColor(type);

    final row = Material(
      color: selected
          ? color.withValues(alpha: 0.12)
          : Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected
              ? color.withValues(alpha: 0.36)
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            SizedBox(
              width: 5,
              height: double.infinity,
              child: ColoredBox(color: color),
            ),
            const SizedBox(width: 11),
            Icon(memoryTypeIcon(type), color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: color, size: 20),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: NotebookPressable(onTap: onTap, child: row),
    );
  }
}
