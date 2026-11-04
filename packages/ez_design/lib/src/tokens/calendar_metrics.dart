import 'package:flutter/material.dart';

import 'app_palette.dart';

const calendarWeekNumberWidth = 24.0;
const calendarGridSpacing = 2.0;

/// Заливка дня: выходные и сокращённые дни отмечены чистым цветом.
Color productionDaySurface(
  Color base, {
  required bool dayOff,
  required bool shortened,
}) {
  if (shortened) return AppPalette.shortenedDay;
  return dayOff ? AppPalette.weekend : base;
}
