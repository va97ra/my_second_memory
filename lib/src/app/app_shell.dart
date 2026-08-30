import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../navigation/active_panel.dart';
import '../navigation/app_destination.dart';
import '../navigation/app_destinations.dart';
import '../navigation/app_router.dart';
import '../navigation/shell_navigation.dart';
import '../navigation/tool_destinations.dart';
import 'page_media.dart';

/// Оболочка приложения: две панели и страница между ними.
///
/// Оболочка живёт одна на всё приложение, выше навигатора: панели не
/// принадлежат странице и не переворачиваются вместе с ней. Раньше каждый
/// маршрут заворачивал себя в свою копию панелей — при переходе в
/// переворачиваемом листе ехала старая пара, под ним стояла новая, и тень
/// листа мелькала по кнопкам.
///
/// Оболочка не знает, что делает конкретная кнопка. Она берёт список пунктов,
/// показывает их и передаёт нажатие тому, кто за него отвечает.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.child, super.key});

  /// Навигатор приложения со всеми его страницами.
  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final GlobalKey<PageTurnFrameState> _pageTurnKey = GlobalKey();
  final PageTurnCoordinator _turnCoordinator = PageTurnCoordinator();

  late final GoRouter _router = ref.read(appRouterProvider);
  late Uri _location = _currentLocation;

  /// Адрес верхней страницы: тот, что последним открыли `go` или `push`.
  /// Список совпадений пуст только до первого разбора адреса.
  Uri get _currentLocation {
    final delegate = _router.routerDelegate;
    final matches = delegate.currentConfiguration;
    return matches.isEmpty ? matches.uri : delegate.state.uri;
  }

  @override
  void initState() {
    super.initState();
    _router.routerDelegate.addListener(_locationChanged);
  }

  @override
  void dispose() {
    _router.routerDelegate.removeListener(_locationChanged);
    _turnCoordinator.dispose();
    super.dispose();
  }

  /// Панели догоняют адрес.
  ///
  /// Делегат сообщает о смене и посреди сборки кадра — пометить панели
  /// грязными в этот момент нельзя, и тогда они догоняют его следующим кадром.
  void _locationChanged() {
    if (!mounted || _currentLocation == _location) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _location = _currentLocation);
      });
      return;
    }
    setState(() => _location = _currentLocation);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final destinations = appDestinations(strings);
    final tools = toolDestinations(strings);
    final activeToolId = toolIdForLocation(_location, tools);
    final panelIndex =
        _indexOf(destinations, panelIdForLocation(_location)) ?? 0;
    final navigation = ShellNavigation(
      router: _router,
      frame: _pageTurnKey,
      activeToolId: activeToolId,
      coordinator: _turnCoordinator,
    );

    return PageTurnCoordinatorScope(
      coordinator: _turnCoordinator,
      // Панели живут выше навигатора, и подсказкам их кнопок нужен свой слой.
      child: OverlayHost(
        child: Scaffold(
          // Страница или модальный лист обрабатывает клавиатуру один раз.
          // Повторное сжатие оболочки схлопывало редактор и двигало фон.
          resizeToAvoidBottomInset: false,
          // Обе панели занимают штатные слоты Scaffold. Когда верхняя панель
          // была первым ребёнком body, создание композитного слоя
          // перелистывания страницы на кадр сбрасывало её кожаную текстуру.
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(NavBarMetrics.toolHeight),
            child: AppToolBar(
              items: [for (final item in tools) item.barItem],
              selectedIndex: _indexOf(tools, activeToolId),
              onSelected: (index) => navigation.selectTool(
                tools[index],
                panel: destinations[panelIndex].id,
              ),
            ),
          ),
          body: PageMedia(
            child: PageTurnFrame(
              key: _pageTurnKey,
              coordinator: _turnCoordinator,
              provideNavigation: true,
              child: AppBackground(child: widget.child),
            ),
          ),
          bottomNavigationBar: AppNavBar(
            items: [for (final item in destinations) item.barItem],
            selectedIndex: activeToolId == null ? panelIndex : null,
            onSelected: (index) => navigation.select(destinations[index]),
          ),
        ),
      ),
    );
  }

  int? _indexOf(List<AppDestination> items, String? id) {
    if (id == null) return null;
    final index = items.indexWhere((item) => item.id == id);
    return index < 0 ? null : index;
  }
}
