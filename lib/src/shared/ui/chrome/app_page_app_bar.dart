import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/app_hints_provider.dart';
import '../page_hint_button.dart';
import 'app_back_button.dart';
import 'header_metrics.dart';

class AppPageAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const AppPageAppBar({
    required this.title,
    this.fallbackLocation,
    this.onBack,
    this.hint,
    this.actions,
    this.bottom,
    this.toolbarHeight = 48,
    super.key,
  }) : assert(fallbackLocation != null || onBack != null);

  final Widget title;
  final String? fallbackLocation;
  final VoidCallback? onBack;

  /// Что можно сделать на этой странице. Кнопка встаёт рядом со стрелкой
  /// «назад», а справа заводится пустой слот той же ширины, иначе заголовок
  /// съедет с середины. Выключенные подсказки убирают и кнопку, и слот.
  final String? hint;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final double toolbarHeight;

  @override
  Size get preferredSize =>
      Size.fromHeight(toolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showHint = hint != null && ref.watch(appHintsProvider);

    return AppBar(
      toolbarHeight: toolbarHeight,
      leadingWidth:
          notebookHeaderSlot * (showHint ? 2 : 1) + headerEdgeInset,
      titleSpacing: 4,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      // AppBar растягивает leading на весь слот, и клавиша выросла бы до
      // ширины слота против размера клавиши в остальных шапках. Align
      // оставляет кнопке её размер, чтобы она была одной и той же везде.
      leading: Padding(
        padding: const EdgeInsets.only(left: headerEdgeInset),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Каждая клавиша стоит в своём слоте одной ширины. Прижатые друг
            // к другу, они читались рядом разного размера: у стрелки поле
            // вокруг значка меньше, чем у круглого знака вопроса.
            SizedBox(
              width: notebookHeaderSlot,
              child: Center(
                child: AppBackButton(
                  fallbackLocation: fallbackLocation,
                  onPressed: onBack,
                ),
              ),
            ),
            if (showHint) PageHintButton(hint: hint!),
          ],
        ),
      ),
      title: title,
      actions: [
        for (final action in actions ?? const <Widget>[])
          SizedBox(
            width: notebookHeaderSlot,
            child: Center(child: action),
          ),
        if (showHint) const SizedBox(width: notebookHeaderSlot),
        const SizedBox(width: headerEdgeInset),
      ],
      bottom: bottom,
    );
  }
}
