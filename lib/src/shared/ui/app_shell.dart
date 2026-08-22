import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_surface_palette.dart';
import '../../core/theme/notebook/notebook_background.dart';
import '../../core/theme/notebook/notebook_leather_surface.dart';
import '../../core/theme/notebook/notebook_visuals.dart';
import 'page_turn_transition.dart';

class AppShell extends StatefulWidget {
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
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final GlobalKey<PageTurnFrameState> _pageTurnKey = GlobalKey();
  final PageTurnCoordinator _turnCoordinator = PageTurnCoordinator();

  @override
  void dispose() {
    _turnCoordinator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final palette = AppSurfacePalette.of(context);
    final notebook = NotebookVisuals.maybeOf(context);
    final navigationShell = widget.navigationShell;
    final branchIndex = navigationShell?.currentIndex ?? widget.currentIndex!;
    final visibleIndex = switch (branchIndex) {
      0 || 1 => branchIndex,
      2 => 3,
      _ => 4,
    };

    return PageTurnCoordinatorScope(
      coordinator: _turnCoordinator,
      child: Scaffold(
        body: navigationShell == null
            ? widget.child
            : PageTurnFrame(
                key: _pageTurnKey,
                coordinator: _turnCoordinator,
                child: PageTurnBranchNavigationScope(
                  onGo: _handleBranchLocation,
                  child: AppBackground(child: navigationShell),
                ),
              ),
        floatingActionButton: widget.floatingActionButton,
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
          // The panel is not a page, so it does not get paper grain: it is the
          // cover the open notebook rests on.
          child: _NavigationSurface(
            color: palette.navigationSurface,
            enabled: notebook != null,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 2, 8, 4),
                child: NavigationBar(
                  selectedIndex: visibleIndex,
                  onDestinationSelected: (index) {
                    if (_turnCoordinator.isBusy) return;
                    if (index == 2) {
                      unawaited(context.pageTurnPush('/memory/note/new'));
                      return;
                    }
                    final targetBranch = index < 2 ? index : index - 1;
                    final shell = navigationShell;
                    if (shell == null) {
                      unawaited(
                        context.pageTurnGo(
                          _locationForBranch(targetBranch),
                        ),
                      );
                      return;
                    }
                    unawaited(_turnToBranch(targetBranch));
                  },
                  destinations: [
                    NavigationDestination(
                      key: const ValueKey('bottom_calendar'),
                      icon: const Icon(Icons.calendar_month_rounded),
                      selectedIcon: const Icon(Icons.calendar_month_rounded),
                      label: strings.calendar,
                    ),
                    NavigationDestination(
                      key: const ValueKey('bottom_feed'),
                      icon: const Icon(Icons.view_agenda_rounded),
                      selectedIcon: const Icon(Icons.view_agenda_rounded),
                      label: strings.feed,
                    ),
                    NavigationDestination(
                      key: const ValueKey('bottom_add_note'),
                      icon: const Icon(Icons.edit_note_rounded),
                      selectedIcon: const Icon(Icons.edit_note_rounded),
                      label: strings.noteCard,
                    ),
                    NavigationDestination(
                      key: const ValueKey('bottom_accounts'),
                      icon: const Icon(Icons.vpn_key_rounded),
                      selectedIcon: const Icon(Icons.vpn_key_rounded),
                      label: strings.accounts,
                    ),
                    NavigationDestination(
                      key: const ValueKey('bottom_settings'),
                      icon: const Icon(Icons.tune_rounded),
                      selectedIcon: const Icon(Icons.tune_rounded),
                      label: strings.settings,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _handleBranchLocation(String location) async {
    final targetBranch = switch (location) {
      '/calendar' => 0,
      '/' => 1,
      '/accounts' => 2,
      '/settings' => 3,
      _ => null,
    };
    if (targetBranch == null) return false;
    await _turnToBranch(targetBranch);
    return true;
  }

  Future<void> _turnToBranch(int targetBranch) async {
    final shell = widget.navigationShell;
    if (shell == null) return;
    if (targetBranch == shell.currentIndex) {
      shell.goBranch(targetBranch, initialLocation: true);
      return;
    }

    final frame = _pageTurnKey.currentState;
    if (frame == null) {
      shell.goBranch(targetBranch);
      return;
    }
    await frame.beginTurn(
      direction: targetBranch > shell.currentIndex
          ? PageTurnDirection.forward
          : PageTurnDirection.backward,
      switchContent: () => shell.goBranch(targetBranch),
    );
  }

  String _locationForBranch(int branch) => switch (branch) {
        0 => '/calendar',
        1 => '/',
        2 => '/accounts',
        _ => '/settings',
      };
}

/// Grain for the navigation panel.
///
/// The panel is not a page, so it does not take the paper texture the sheets
/// wear: it reads as the cover the open notebook rests on. Outside the
/// notebook theme it stays as it was.
class _NavigationSurface extends StatelessWidget {
  const _NavigationSurface({
    required this.color,
    required this.enabled,
    required this.child,
  });

  final Color color;
  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    // The flat colour underneath keeps the panel readable if the leather
    // asset is not ready yet.
    return ColoredBox(
      color: color,
      child: NotebookLeatherSurface(
        color: color,
        lightweight: true,
        child: child,
      ),
    );
  }
}
