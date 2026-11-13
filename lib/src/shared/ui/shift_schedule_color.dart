import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/painting.dart';

/// Цвет графика смен в теме [colors]: выбранный для неё в карточке темы, а
/// если не выбран — записанный в самом графике.
Color shiftScheduleColor(AppThemeColors colors, ShiftSchedule schedule) =>
    colors.shift(schedule.id, Color(schedule.colorValue));
