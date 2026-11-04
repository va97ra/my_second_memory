import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/app_hints_provider.dart';
import '../page_hint_button.dart';
import 'app_back_button.dart';

/// Шапка главной страницы: одна маленькая карточка на все страницы.
///
/// Сведения — либо просто [title], либо своя сборка [center] на основе
/// [NotebookHeaderTitle].
class MainPageHeader extends ConsumerWidget {
  const MainPageHeader({
    this.title,
    this.center,
    this.backLocation,
    this.hint,
    this.leading = const [],
    this.trailing = const [],
    this.cardKey,
    super.key,
  }) : assert((title == null) != (center == null));

  final String? title;
  final Widget? center;
  final String? backLocation;

  /// Что можно сделать на этой странице. Кнопка встаёт второй от края.
  ///
  /// Выключенные подсказки убирают и кнопку, и слот: шапка не остаётся с дырой
  /// на месте кнопки.
  final String? hint;

  /// Кнопки слева, первая стоит у самого края.
  final List<Widget> leading;

  /// Кнопки справа, последняя стоит у самого края.
  final List<Widget> trailing;
  final Key? cardKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final left = [
      if (backLocation case final location?)
        AppBackButton(fallbackLocation: location),
      ...leading,
    ];
    if (hint != null && ref.watch(appHintsProvider)) {
      left.insert(left.isEmpty ? 0 : 1, PageHintButton(hint: hint!));
    }
    return NotebookPageHeader(
      cardKey: cardKey,
      leading: left,
      trailing: trailing,
      child: center ??
          NotebookHeaderTitle(
            title: Text(title!, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
    );
  }
}
