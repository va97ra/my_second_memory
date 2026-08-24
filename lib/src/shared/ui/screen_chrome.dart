import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:ez_design/ez_design.dart';
import '../../navigation/page_turn_navigation.dart';

class WarmGradientBackground extends StatelessWidget {
  const WarmGradientBackground({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // The app shell owns the shared background. Keeping screen wrappers
    // transparent avoids decoding and painting the same texture twice.
    return child;
  }
}

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
      leadingWidth: 64,
      titleSpacing: 4,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: AppBackButton(
          fallbackLocation: fallbackLocation,
          onPressed: onBack,
        ),
      ),
      title: title,
      actions: [
        ...?actions,
        const SizedBox(width: 16),
      ],
      bottom: bottom,
    );
  }
}

class AppLabeledDivider extends StatelessWidget {
  const AppLabeledDivider({
    required this.label,
    this.padding = const EdgeInsets.fromLTRB(16, 3, 16, 3),
    this.trailingIcon,
    super.key,
  });

  final String label;
  final EdgeInsetsGeometry padding;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notebook = NotebookVisuals.maybeOf(context);
    // Ink, not black: on the dark notebook a black rule and a black label are
    // invisible against the page.
    final color = notebook != null
        ? notebook.ink.withValues(alpha: 0.82)
        : theme.colorScheme.onSurface.withValues(alpha: 0.58);
    return Padding(
      padding: padding,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 22),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final centerWidth =
                (constraints.maxWidth * 0.68).clamp(160.0, 360.0);
            return Row(
              children: [
                Expanded(
                  child: ColoredBox(
                    key: const ValueKey('labeled_divider_left_line'),
                    color: color,
                    child: const SizedBox(height: 1.5),
                  ),
                ),
                SizedBox(
                  width: centerWidth,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (trailingIcon != null) const SizedBox(width: 20),
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (trailingIcon != null) ...[
                          const SizedBox(width: 4),
                          Icon(trailingIcon, size: 16, color: color),
                        ],
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ColoredBox(
                    key: const ValueKey('labeled_divider_right_line'),
                    color: color,
                    child: const SizedBox(height: 1.5),
                  ),
                ),
              ],
            );
          },
        ),
      ),
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

/// Width claimed on each side of a header title, so the title stays centred on
/// the header rather than on the leftover space. Whatever sits in a slot is
/// pushed to the page edge.
const double _mainHeaderSlot = 48;

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
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: Row(
          children: [
            // A centred title needs the same width claimed on either side of
            // it, whether or not there is a back button to put there.
            SizedBox(
              width: _mainHeaderSlot,
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
              width: _mainHeaderSlot,
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
