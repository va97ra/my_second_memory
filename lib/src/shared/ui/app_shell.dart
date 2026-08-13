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
    final branchIndex = navigationShell?.currentIndex ?? currentIndex!;
    final visibleIndex = switch (branchIndex) {
      0 || 1 => branchIndex,
      2 => 3,
      _ => 4,
    };

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
          gradient: palette.navigationGradient,
          border: Border(
            top: BorderSide(
              color: palette.borderStart.withValues(alpha: 0.78),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.24),
              blurRadius: 22,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 8, 4),
            child: NavigationBar(
              selectedIndex: visibleIndex,
              onDestinationSelected: (index) {
                if (index == 2) {
                  context.push('/memory/note/new');
                  return;
                }
                final targetBranch = index < 2 ? index : index - 1;
                final shell = navigationShell;
                if (shell != null) {
                  shell.goBranch(
                    targetBranch,
                    initialLocation: targetBranch == shell.currentIndex,
                  );
                  return;
                }
                context.go(switch (targetBranch) {
                  0 => '/',
                  1 => '/calendar',
                  2 => '/accounts',
                  _ => '/settings',
                });
              },
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.view_agenda_rounded),
                  selectedIcon: const Icon(Icons.view_agenda_rounded),
                  label: strings.feed,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.calendar_month_rounded),
                  selectedIcon: const Icon(Icons.calendar_month_rounded),
                  label: strings.calendar,
                ),
                NavigationDestination(
                  key: const ValueKey('bottom_add_note'),
                  icon: const Icon(Icons.edit_note_rounded),
                  selectedIcon: const Icon(Icons.edit_note_rounded),
                  label: strings.noteCard,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.vpn_key_rounded),
                  selectedIcon: const Icon(Icons.vpn_key_rounded),
                  label: strings.accounts,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.tune_rounded),
                  selectedIcon: const Icon(Icons.tune_rounded),
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
