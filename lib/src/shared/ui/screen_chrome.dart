import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/notebook/notebook_visuals.dart';

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
          context.pop();
          return;
        }
        context.go(fallbackLocation!);
      },
      icon: const Icon(Icons.arrow_back, size: 22),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      style: IconButton.styleFrom(
        fixedSize: const Size.square(40),
        minimumSize: const Size.square(40),
        maximumSize: const Size.square(40),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
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
    super.key,
  }) : assert(fallbackLocation != null || onBack != null);

  final Widget title;
  final String? fallbackLocation;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(48 + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 48,
      leadingWidth: 56,
      titleSpacing: 4,
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
      actions: actions,
      bottom: bottom,
    );
  }
}

class AppLabeledDivider extends StatelessWidget {
  const AppLabeledDivider({
    required this.label,
    this.padding = const EdgeInsets.fromLTRB(16, 3, 16, 3),
    super.key,
  });

  final String label;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = NotebookVisuals.maybeOf(context) != null
        ? Colors.black.withValues(alpha: 0.82)
        : theme.colorScheme.onSurface.withValues(alpha: 0.58);
    return Padding(
      padding: padding,
      child: SizedBox(
        height: 22,
        child: Row(
          children: [
            Expanded(
                child: ColoredBox(
                    color: color, child: const SizedBox(height: 1.5))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
                child: ColoredBox(
                    color: color, child: const SizedBox(height: 1.5))),
          ],
        ),
      ),
    );
  }
}

class MainSliverAppBar extends StatelessWidget {
  const MainSliverAppBar({
    required this.title,
    this.backLocation,
    super.key,
  });

  final String title;
  final String? backLocation;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: MainPageHeader(title: title, backLocation: backLocation),
    );
  }
}

class MainPageHeader extends StatelessWidget {
  const MainPageHeader({
    required this.title,
    this.backLocation,
    super.key,
  });

  final String title;
  final String? backLocation;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: Row(
          children: [
            if (backLocation != null) ...[
              AppBackButton(fallbackLocation: backLocation!),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
