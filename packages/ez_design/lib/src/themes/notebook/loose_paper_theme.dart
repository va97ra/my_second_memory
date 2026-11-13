import 'package:flutter/material.dart';

import '../../tokens/content_typography.dart';
import '../app_theme_colors.dart';
import 'notebook_theme.dart';

/// Светлые блокноты, уже собранные под чьи-то цвета. Тем две, и в настройках
/// видны обе сразу, так что больше пары-тройки здесь не живёт.
final _byColors = <AppThemeColors, ThemeData>{};

/// Схема светлого листа, лежащего на странице [page].
///
/// Чернила, границы и зерно у листа свои, светлые, а цвета — страницы: они
/// принадлежат выбравшему их человеку, а не бумаге. Шрифт записей тоже его.
ThemeData loosePaperTheme(ThemeData page) {
  final colors =
      page.extension<AppThemeColors>() ?? AppThemeColors(page.brightness);
  if (_byColors.length > 4) _byColors.clear();
  final paper = _byColors[colors] ??= buildNotebookTheme(
    brightness: Brightness.light,
    colors: colors,
  );
  final content = page.extension<AppContentTypography>();
  if (content == null) return paper;
  return paper.copyWith(extensions: [...paper.extensions.values, content]);
}
