import 'package:flutter/material.dart';

import '../themes/app_theme_colors.dart';

const calendarWeekNumberWidth = 24.0;
const calendarGridSpacing = 2.0;

/// Заливка дня: выходные и сокращённые дни отмечены своим цветом темы.
Color productionDaySurface(
  Color base,
  AppThemeColors colors, {
  required bool dayOff,
  required bool shortened,
}) {
  if (shortened) return colors[AppColorRole.shortenedDay];
  return dayOff ? colors[AppColorRole.weekend] : base;
}
