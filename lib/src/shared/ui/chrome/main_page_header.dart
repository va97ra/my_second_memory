import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/app_hints_provider.dart';
import '../page_hint_button.dart';
import 'app_back_button.dart';
import 'header_metrics.dart';

class MainPageHeader extends ConsumerWidget {
  const MainPageHeader({
    required this.title,
    this.backLocation,
    this.hint,
    this.trailing,
    super.key,
  });

  final String title;
  final String? backLocation;

  /// Что можно сделать на этой странице. Кнопка встаёт слева, а справа
  /// заводится пустой слот той же ширины: иначе заголовок съедет с середины.
  ///
  /// Выключенные подсказки убирают и кнопку, и слот: шапка возвращается
  /// к прежней ширине, а не остаётся с дырой на месте кнопки.
  final String? hint;

  /// Sits in the trailing slot, flush with the edge of the page.
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showHint = hint != null && ref.watch(appHintsProvider);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          headerEdgeInset,
          4,
          headerEdgeInset,
          4,
        ),
        child: Row(
          children: [
            // A centred title needs the same width claimed on either side of
            // it, whether or not there is a back button to put there.
            SizedBox(
              width: notebookHeaderSlot,
              child: backLocation == null
                  ? null
                  : Align(
                      alignment: Alignment.centerLeft,
                      child: AppBackButton(fallbackLocation: backLocation!),
                    ),
            ),
            if (showHint) PageHintButton(hint: hint!),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ),
            if (showHint) const SizedBox(width: notebookHeaderSlot),
            SizedBox(
              width: notebookHeaderSlot,
              child: trailing == null
                  ? null
                  : Align(alignment: Alignment.centerRight, child: trailing),
            ),
          ],
        ),
      ),
    );
  }
}
