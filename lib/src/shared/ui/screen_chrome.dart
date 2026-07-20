import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_surface_palette.dart';

class WarmGradientBackground extends StatelessWidget {
  const WarmGradientBackground({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppSurfacePalette.of(context).backgroundGradient,
      ),
      child: child,
    );
  }
}

class AppBackButton extends StatelessWidget {
  const AppBackButton({
    required this.fallbackLocation,
    super.key,
  });

  final String fallbackLocation;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () {
        if (context.canPop()) {
          context.pop();
          return;
        }
        context.go(fallbackLocation);
      },
      icon: const Icon(Icons.arrow_back),
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
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
        child: Row(
          children: [
            if (backLocation != null) ...[
              AppBackButton(fallbackLocation: backLocation!),
              const SizedBox(width: 2),
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
