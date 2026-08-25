/// Оболочка приложения: как оно выглядит и по каким размерам собрано.
///
/// Пакет не знает ни о записях, ни о хранилище, ни о синхронизации: он умеет
/// только рисовать. Всё, что зависит от данных пользователя, живёт в
/// приложении и передаётся сюда параметрами.
library;

export 'src/components/empty_state.dart';
export 'src/components/labeled_divider.dart';
export 'src/components/nav_bar/app_nav_bar.dart';
export 'src/components/nav_bar/nav_bar_item.dart';
export 'src/components/nav_bar/nav_bar_metrics.dart';
export 'src/components/nav_bar/nav_bar_style.dart';
export 'src/components/notebook_action_button.dart';
export 'src/components/notebook_icon_button.dart';
export 'src/components/notebook_page_header.dart';
export 'src/components/notebook_pressable.dart';
export 'src/components/page_swipe_area.dart';
export 'src/components/page_turn/page_turn_branch_navigation_scope.dart';
export 'src/components/page_turn/page_turn_coordinator.dart';
export 'src/components/page_turn/page_turn_frame.dart';
export 'src/components/page_turn/page_turn_geometry.dart'
    show PageTurnGeometry, PageTurnGeometryPoint;
export 'src/components/torn_paper_shape_border.dart';
export 'src/components/warm_gradient_background.dart';
export 'src/themes/app_theme.dart';
export 'src/themes/app_theme_style.dart';
export 'src/themes/notebook/notebook_assets.dart';
export 'src/themes/notebook/notebook_background.dart';
export 'src/themes/notebook/notebook_leather_surface.dart';
export 'src/themes/notebook/notebook_paper_island.dart';
export 'src/themes/notebook/notebook_theme.dart';
export 'src/themes/notebook/notebook_visuals.dart';
export 'src/themes/surface_palette.dart';
export 'src/themes/surface_textures.dart';
export 'src/tokens/content_typography.dart';
