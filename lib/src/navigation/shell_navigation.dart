import 'package:ez_design/ez_design.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'app_destination.dart';

/// Что делает нажатие на панель.
///
/// Оболочка занята разметкой: две панели и страница между ними. Куда ведёт
/// кнопка и как туда переходят — сменой адреса с переворотом листа, маршрутом
/// поверх страницы или подменой открытого инструмента — знает этот объект.
///
/// Адрес он меняет напрямую через [router], а не через `BuildContext`: панели
/// живут выше навигатора, и обычные расширения контекста там его не находят.
/// Живёт объект одну сборку: своего состояния у него нет, только доступ к
/// чужому.
class ShellNavigation {
  const ShellNavigation({
    required this.router,
    required this.frame,
    required this.activeToolId,
    required this.coordinator,
  });

  final GoRouter router;

  /// Лист, которым оболочка переворачивает страницу. Пока его нет в дереве,
  /// адрес меняется без переворота.
  final GlobalKey<PageTurnFrameState> frame;

  final String? activeToolId;
  final PageTurnCoordinator coordinator;

  /// Пункт нижней панели. Вкладка сменяется адресом — вкладки помнят своё
  /// состояние сами; всё остальное открывается поверх страницы, чтобы туда
  /// можно было вернуться назад.
  void select(AppDestination destination) {
    if (coordinator.isBusy || _openSheet(destination)) return;
    _turnTo(() {
      if (destination.isBranch) {
        router.go(destination.location);
      } else {
        router.push<void>(destination.location);
      }
    });
  }

  /// Инструмент верхней панели. Открытый инструмент сменяется другим на
  /// месте, чтобы возврат вёл на страницу, а не на прошлый инструмент;
  /// [panel] — пункт, с которого инструмент открыли: панель под ним остаётся
  /// прежней.
  void selectTool(AppDestination destination, {required String panel}) {
    if (coordinator.isBusy || destination.id == activeToolId) return;
    if (_openSheet(destination)) return;
    if (destination.isBranch) {
      // Вкладка оболочки с кнопкой наверху: адрес меняется целиком, как и с
      // нижней панели, — вкладка помнит своё состояние сама.
      _turnTo(() => router.go(destination.location));
      return;
    }
    final location = '${destination.location}?panel=$panel';
    if (activeToolId != null) {
      // Верхние инструменты — вкладки одного места, а не следующие страницы.
      // Переворот здесь показывал снимок старого инструмента поверх нового.
      // У страниц инструментов нет собственного маршрутного затухания, поэтому
      // обычная замена стека меняет содержимое одним кадром и с новым page key.
      router.pushReplacement(location);
      return;
    }
    _turnTo(() => router.push<void>(location));
  }

  /// Лист открывается в навигаторе, а не в оболочке: так он ложится между
  /// панелями и меряет высоту от листа страницы, как и все листы. Не лист —
  /// false, и кнопка ведёт по адресу.
  bool _openSheet(AppDestination destination) {
    final openSheet = destination.openSheet;
    if (openSheet == null) return false;
    final navigatorContext = router.routerDelegate.navigatorKey.currentContext;
    if (navigatorContext != null) openSheet(navigatorContext);
    return true;
  }

  void _turnTo(VoidCallback go) {
    final page = frame.currentState;
    if (page == null) {
      go();
      return;
    }
    page.beginTurn(direction: PageTurnDirection.forward, switchContent: go);
  }
}
