import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:ez_design/ez_design.dart';
import '../../navigation/page_turn_navigation.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({
    this.fallbackLocation,
    this.onPressed,
    super.key,
  }) : assert(fallbackLocation != null || onPressed != null);

  final String? fallbackLocation;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const ValueKey('app_back'),
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () {
        if (onPressed != null) {
          onPressed!();
          return;
        }
        if (context.canPop()) {
          unawaited(context.pageTurnPop());
          return;
        }
        unawaited(
          context.pageTurnGo(
            fallbackLocation!,
            direction: PageTurnDirection.backward,
          ),
        );
      },
      icon: const Icon(Icons.arrow_back_rounded, size: 22),
      style: notebookIconButtonStyle(),
    );
  }
}

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
      leadingWidth: notebookHeaderSlot + _headerEdgeInset,
      titleSpacing: 4,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      // AppBar растягивает leading на весь слот, и клавиша выросла бы до
      // ширины слота против размера клавиши в остальных шапках. Align
      // оставляет кнопке её размер, чтобы она была одной и той же везде.
      leading: Padding(
        padding: const EdgeInsets.only(left: _headerEdgeInset),
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
        const SizedBox(width: _headerEdgeInset),
      ],
      bottom: bottom,
    );
  }
}

class MainSliverAppBar extends StatelessWidget {
  const MainSliverAppBar({
    required this.title,
    this.backLocation,
    this.trailing,
    super.key,
  });

  final String title;
  final String? backLocation;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: MainPageHeader(
        title: title,
        backLocation: backLocation,
        trailing: trailing,
      ),
    );
  }
}

/// Отступ содержимого шапки от края страницы.
const double _headerEdgeInset = 16;

class MainPageHeader extends StatelessWidget {
  const MainPageHeader({
    required this.title,
    this.backLocation,
    this.trailing,
    super.key,
  });

  final String title;
  final String? backLocation;

  /// Sits in the trailing slot, flush with the edge of the page.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          _headerEdgeInset,
          4,
          _headerEdgeInset,
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
