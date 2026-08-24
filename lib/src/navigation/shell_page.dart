import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../app/app_shell.dart';
import 'page_turn_transition.dart';

/// Страница, открытая поверх вкладки.
///
/// Нижняя панель остаётся на месте: человек не проваливается вглубь, а
/// заглядывает в запись и должен иметь возможность уйти оттуда туда же, куда
/// уходит всегда. [panel] говорит, какой пункт держать подсвеченным — тот, из
/// которого экран открыли.
Page<void> shellPage({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
  required String panel,
  String? backFallback,
  bool interceptBack = true,
}) {
  return pageTurnPage(
    context: context,
    state: state,
    backFallback: backFallback,
    interceptBack: interceptBack,
    child: AppShell(activeDestinationId: panel, child: child),
  );
}

/// Пункт панели, из которого открыт экран записи.
///
/// Записку заводят с центральной кнопки, всё остальное — из ленты, поэтому
/// адрес несёт пункт только когда он отличается от обычного.
String recordPanelOf(GoRouterState state) =>
    state.uri.queryParameters['panel'] ?? 'feed';
