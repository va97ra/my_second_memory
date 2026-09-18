import 'package:flutter/material.dart';

const calendarWeekNumberWidth = 24.0;
const calendarGridSpacing = 2.0;

/// Day backgrounds remain quieter than shift caps and event ribbons.
Color productionDaySurface(Color base,
    {required bool dayOff, required bool shortened}) {
  final tint = shortened ? const Color(0xFFE5A51A) : const Color(0xFFE66074);
  return dayOff || shortened
      ? Color.alphaBlend(tint.withValues(alpha: 0.26), base)
      : base;
}
