import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import '../../../../shared/ui/memory_card/memory_item_presentation.dart';

/// Квадратик в углу листка: зелёная галочка у записи в работе,
/// серая у выполненной. Рисуется мелко, а нажимается с запасом вокруг.
class MemoryStickerDoneBox extends StatelessWidget {
  const MemoryStickerDoneBox({
    super.key,
    required this.isDone,
    required this.onToggle,
  });

  static const boxSize = 20.0;
  static const _touchSize = 44.0;
  static const _edgeInset = 6.0;
  static const _active = AppPalette.success;

  final bool isDone;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final color = isDone ? memoryDoneColor : _active;

    return Semantics(
      button: true,
      checked: isDone,
      label: isDone ? strings.markActive : strings.markDone,
      excludeSemantics: true,
      child: NotebookPressable(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox.square(
          dimension: _touchSize,
          child: Padding(
            padding: const EdgeInsets.all(_edgeInset),
            child: Align(
              alignment: Alignment.bottomRight,
              child: Container(
                width: boxSize,
                height: boxSize,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color, width: 1.4),
                ),
                child: Icon(Icons.check_rounded, size: 16, color: color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
