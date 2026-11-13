import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_theme_colors_controller.dart';

/// Тема [style] с цветами, которые выбрал для неё человек.
///
/// Собирается один раз и пересобирается, только когда меняются её цвета: ею
/// рисуются и всё приложение, и плитка темы, и открытая карточка темы.
final appThemeDataProvider =
    Provider.family<ThemeData, AppThemeStyle>((ref, style) {
  final colors = ref.watch(
    appThemeColorsControllerProvider.select((all) => all[style]!),
  );
  return buildNotebookTheme(brightness: brightnessOf(style), colors: colors);
});
