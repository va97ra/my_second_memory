import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import '../../../../shared/ui/page_hint_button.dart';

/// Шапка панели: подсказка слева, имя посередине, справа — очистить
/// разговор. Пустой разговор очищать нечего, но слот остаётся той же ширины,
/// иначе имя съезжает с середины (`docs/layout.md`).
class JarvisSheetHeader extends StatelessWidget {
  const JarvisSheetHeader({this.onClear, super.key});

  /// Null — разговор пуст.
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Row(
      children: [
        SizedBox(
          width: notebookHeaderSlot,
          child: PageHintButton(hint: strings.jarvisPageHint),
        ),
        Expanded(
          child: Text(
            strings.jarvis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        SizedBox(
          width: notebookHeaderSlot,
          child: onClear == null
              ? null
              : IconButton(
                  key: const ValueKey('jarvis_clear'),
                  tooltip: strings.jarvisClear,
                  onPressed: onClear,
                  icon: const Icon(Icons.delete_sweep_rounded),
                ),
        ),
      ],
    );
  }
}
