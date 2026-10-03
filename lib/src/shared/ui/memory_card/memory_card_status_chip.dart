import 'package:flutter/material.dart';

import 'memory_item_presentation.dart';

/// Отметка «выполнено» в плотной карточке.
class MemoryCardStatusChip extends StatelessWidget {
  const MemoryCardStatusChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: memoryDoneColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: memoryDoneColor.withValues(alpha: 0.52),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Text(
          label,
          maxLines: 1,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: memoryDoneColor,
                fontSize: 7.5,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
        ),
      ),
    );
  }
}
