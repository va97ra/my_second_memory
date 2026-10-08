import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import '../../../../shared/ui/page_hint_button.dart';

/// Шапка панели: подсказка слева, имя посередине. Справа пустой слот той же
/// ширины — иначе имя съезжает с середины (`docs/layout.md`).
class JarvisSheetHeader extends StatelessWidget {
  const JarvisSheetHeader({super.key});

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
        const SizedBox(width: notebookHeaderSlot),
      ],
    );
  }
}
