import 'dart:async';

import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../navigation/app_destination.dart';
import '../navigation/app_destinations.dart';
import '../navigation/page_turn_navigation.dart';

/// Оболочка приложения: страница, нижняя панель и перелистывание между ними.
///
/// Оболочка не знает, что делает конкретная кнопка. Она берёт список пунктов,
/// показывает их и передаёт нажатие тому, кто за него отвечает: ветка
/// переключается перелистыванием, маршрут открывается поверх страницы.
class AppShell extends StatefulWidget {
  const AppShell({
    this.navigationShell,
    this.activeDestinationId,
    this.child,
    this.floatingActionButton,
    super.key,
  }) : assert(
          navigationShell != null || child != null,
          'оболочке нужна либо ветка, либо своя страница',
        );

  final StatefulNavigationShell? navigationShell;

  /// Какой пункт подсветить у экрана, живущего вне веток.
  final String? activeDestinationId;
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
    final destinations = appDestinations(AppStrings.of(context));
    final navigationShell = widget.navigationShell;

    return PageTurnCoordinatorScope(
      coordinator: _turnCoordinator,
      child: Scaffold(
        body: navigationShell == null
            ? widget.child
            : PageTurnFrame(
                key: _pageTurnKey,
                coordinator: _turnCoordinator,
                child: PageTurnBranchNavigationScope(
                  onGo: (location) => _openLocation(destinations, location),
                  child: AppBackground(child: navigationShell),
                ),
              ),
        floatingActionButton: widget.floatingActionButton,
        bottomNavigationBar: AppNavBar(
          items: [for (final item in destinations) item.barItem],
          selectedIndex: _selectedIndex(destinations),
          onSelected: (index) => _select(destinations[index]),
        ),
      ),
    );
  }

  /// Подсвечен пункт текущей ветки, а для экрана вне веток — тот, из которого
  /// в него пришли.
  int _selectedIndex(List<AppDestination> destinations) {
    final branch = widget.navigationShell?.currentIndex;
    final index = destinations.indexWhere(
      (item) => branch == null
          ? item.id == widget.activeDestinationId
          : item.isBranch && item.branchIndex == branch,
    );
    return index < 0 ? 0 : index;
  }

  void _select(AppDestination destination) {
    if (_turnCoordinator.isBusy) return;
    if (!destination.isBranch) {
      unawaited(context.pageTurnPush(destination.location));
      return;
    }
    if (widget.navigationShell == null) {
      unawaited(context.pageTurnGo(destination.location));
      return;
    }
    unawaited(_turnToBranch(destination.branchIndex));
  }

  /// Переход по адресу изнутри страницы: если адрес принадлежит ветке, она
  /// переключается перелистыванием, а не подменой всего экрана.
  Future<bool> _openLocation(
    List<AppDestination> destinations,
    String location,
  ) async {
    final index = destinations.indexWhere(
      (item) => item.isBranch && item.location == location,
    );
    if (index < 0) return false;
    await _turnToBranch(destinations[index].branchIndex);
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
}
