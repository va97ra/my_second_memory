import 'package:ez_design/ez_design.dart';

/// Название темы для настроек и для выбора оформления.
///
/// Одно на оба места: строка выбранной темы в настройках и подпись под её
/// образцом — это одно и то же название, и расходиться им незачем.
String themeStyleLabel(AppThemeStyle style, {required bool isRu}) {
  return switch (style) {
    AppThemeStyle.notebookLight => isRu ? 'Светлая' : 'Light',
    AppThemeStyle.notebookDark => isRu ? 'Тёмная' : 'Dark',
    AppThemeStyle.cosmos => isRu ? 'Космос' : 'Cosmos',
    AppThemeStyle.cyberpunk => isRu ? 'Киберпанк' : 'Cyberpunk',
  };
}
