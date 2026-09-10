import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import '../page_hint_button.dart';
import 'app_back_button.dart';
import 'header_metrics.dart';

class AppPageAppBar extends StatelessWidget implements PreferredSizeWidget {
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
  /// съедет с середины.
  final String? hint;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final double toolbarHeight;

  @override
  Size get preferredSize =>
      Size.fromHeight(toolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: toolbarHeight,
      leadingWidth:
          notebookHeaderSlot * (hint == null ? 1 : 2) + headerEdgeInset,
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
            AppBackButton(
              fallbackLocation: fallbackLocation,
              onPressed: onBack,
            ),
            if (hint case final text?)
              SizedBox(
                width: notebookHeaderSlot,
                child: PageHintButton(hint: text),
              ),
          ],
        ),
      ),
      title: title,
      actions: [
        ...?actions,
        if (hint != null) const SizedBox(width: notebookHeaderSlot),
        const SizedBox(width: headerEdgeInset),
      ],
      bottom: bottom,
    );
  }
}
