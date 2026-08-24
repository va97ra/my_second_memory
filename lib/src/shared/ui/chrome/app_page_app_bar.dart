import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import 'app_back_button.dart';
import 'header_metrics.dart';

class AppPageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppPageAppBar({
    required this.title,
    this.fallbackLocation,
    this.onBack,
    this.actions,
    this.bottom,
    this.toolbarHeight = 48,
    super.key,
  }) : assert(fallbackLocation != null || onBack != null);

  final Widget title;
  final String? fallbackLocation;
  final VoidCallback? onBack;
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
      leadingWidth: notebookHeaderSlot + headerEdgeInset,
      titleSpacing: 4,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      // AppBar растягивает leading на весь слот, и клавиша выросла бы до
      // ширины слота против размера клавиши в остальных шапках. Align
      // оставляет кнопке её размер, чтобы она была одной и той же везде.
      leading: Padding(
        padding: const EdgeInsets.only(left: headerEdgeInset),
        child: Align(
          alignment: Alignment.centerLeft,
          child: AppBackButton(
            fallbackLocation: fallbackLocation,
            onPressed: onBack,
          ),
        ),
      ),
      title: title,
      actions: [
        ...?actions,
        const SizedBox(width: headerEdgeInset),
      ],
      bottom: bottom,
    );
  }
}
