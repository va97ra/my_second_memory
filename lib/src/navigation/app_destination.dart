import 'package:ez_design/ez_design.dart';
import 'package:flutter/widgets.dart';

/// Куда ведёт кнопка панели.
///
/// Ветка — вкладка оболочки, которая помнит своё состояние между переходами.
/// Маршрут — экран, открытый поверх текущей вкладки. Лист — панель поверх
/// той страницы, где человек сейчас: страница под ней не меняется.
enum NavTarget { branch, route, sheet }

/// Пункт нижней панели вместе с его назначением.
///
/// Это данные, а не код: чтобы добавить кнопку, добавляют запись в
/// `appDestinations`. Ни панель, ни оболочка при этом не меняются, и ни одна
/// кнопка не является особым случаем внутри обработчика.
@immutable
class AppDestination {
  const AppDestination.branch({
    required this.id,
    required this.icon,
    required this.label,
    required this.location,
    required this.branchIndex,
  })  : target = NavTarget.branch,
        openSheet = null,
        assert(branchIndex >= 0, 'ветка не может быть отрицательной');

  const AppDestination.route({
    required this.id,
    required this.icon,
    required this.label,
    required this.location,
  })  : target = NavTarget.route,
        branchIndex = -1,
        openSheet = null;

  /// Лист поверх страницы. Адреса у листа нет: страница под ним остаётся
  /// той же, и подсвечивать на панели нечего.
  const AppDestination.sheet({
    required this.id,
    required this.icon,
    required this.label,
    required void Function(BuildContext navigatorContext) this.openSheet,
  })  : target = NavTarget.sheet,
        location = '',
        branchIndex = -1;

  /// Стабильный ключ пункта. По нему строится ключ кнопки в панели.
  final String id;
  final IconData icon;
  final String label;

  /// Путь, который представляет пункт.
  final String location;
  final NavTarget target;

  /// Индекс ветки оболочки. Осмыслен только для [NavTarget.branch].
  final int branchIndex;

  /// Как открыть лист. Только у [NavTarget.sheet]; получает контекст
  /// навигатора — лист живёт в нём, между панелями.
  final void Function(BuildContext navigatorContext)? openSheet;

  bool get isBranch => target == NavTarget.branch;

  NavBarItem get barItem => NavBarItem(id: id, icon: icon, label: label);
}
