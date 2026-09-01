import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

import '../../tool_data/tool_data.dart';

/// Свободное место в верхней панели.
///
/// Кнопка и её место в панели сохранены нарочно: инструмент, который здесь
/// стоял, удалён, а слот ждёт следующего. Экран честно говорит, что пусто,
/// вместо того чтобы притворяться разделом.
class EmptyToolScreen extends StatelessWidget {
  const EmptyToolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return ToolPageFrame(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.widgets_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                strings.emptySlot,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                strings.emptySlotHint,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
