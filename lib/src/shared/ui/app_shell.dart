import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_surface_palette.dart';
import 'page_turn_transition.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    this.navigationShell,
    this.currentIndex,
    this.child,
    this.floatingActionButton,
    super.key,
  }) : assert(
            navigationShell != null || (currentIndex != null && child != null));

  final StatefulNavigationShell? navigationShell;
  final int? currentIndex;
  final Widget? child;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final palette = AppSurfacePalette.of(context);

    return Scaffold(
      body: navigationShell == null
          ? child
          : PageTurnTabFrame(
              index: navigationShell!.currentIndex,
              child: navigationShell!,
            ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.navigationSurface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 8, 4),
            child: NavigationBar(
              selectedIndex: navigationShell?.currentIndex ?? currentIndex!,
              onDestinationSelected: (index) {
                final shell = navigationShell;
                if (shell != null) {
                  shell.goBranch(
                    index,
                    initialLocation: index == shell.currentIndex,
                  );
                  return;
                }
                context.go(switch (index) {
                  0 => '/',
                  1 => '/calendar',
                  2 => '/accounts',
                  _ => '/settings',
                });
              },
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.view_day_outlined),
                  selectedIcon: const Icon(Icons.view_day),
                  label: strings.feed,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.calendar_month_outlined),
                  selectedIcon: const Icon(Icons.calendar_month),
                  label: strings.calendar,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.key_outlined),
                  selectedIcon: const Icon(Icons.key),
                  label: strings.accounts,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.tune_outlined),
                  selectedIcon: const Icon(Icons.tune),
                  label: strings.settings,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
