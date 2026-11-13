import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import '../../../../shared/ui/memory_card/memory_item_presentation.dart';

/// Что перекрашивают в карточке темы: цвет темы или график смен.
sealed class ThemeColorTarget {
  const ThemeColorTarget();

  /// Выбранный цвет как есть, с прозрачностью.
  Color picked(AppThemeColors colors);

  /// Готовый цвет на своей подложке — им и нарисован образец.
  Color resolved(AppThemeColors colors);

  bool isChanged(AppThemeColors colors);

  /// Те же цвета темы, где у этой цели [color]; `null` — исходный.
  AppThemeColors apply(AppThemeColors colors, Color? color);

  String label({required bool isRu});
}

final class ThemeRoleTarget extends ThemeColorTarget {
  const ThemeRoleTarget(this.role) : type = null;

  /// Вид записи как цель: подпись и значок берутся у самого вида.
  ThemeRoleTarget.type(MemoryType this.type) : role = memoryTypeColorRole(type);

  final AppColorRole role;
  final MemoryType? type;

  @override
  Color picked(AppThemeColors colors) => colors.picked(role);

  @override
  Color resolved(AppThemeColors colors) => colors[role];

  @override
  bool isChanged(AppThemeColors colors) => colors.isChanged(role);

  @override
  AppThemeColors apply(AppThemeColors colors, Color? color) =>
      colors.withColor(role, color);

  @override
  String label({required bool isRu}) => switch (type) {
        final type? => type.label(isRu ? 'ru' : 'en'),
        null => switch (role) {
            AppColorRole.weekend => isRu ? 'Выходные' : 'Days off',
            AppColorRole.shortenedDay =>
              isRu ? 'Сокращённый день' : 'Shortened day',
            AppColorRole.today => isRu ? 'Сегодня' : 'Today',
            _ => isRu ? 'Кнопки' : 'Buttons',
          },
      };

  @override
  bool operator ==(Object other) =>
      other is ThemeRoleTarget && other.role == role;

  @override
  int get hashCode => role.hashCode;

  @override
  String toString() => role.name;
}

final class ThemeShiftTarget extends ThemeColorTarget {
  const ThemeShiftTarget(this.schedule);

  final ShiftSchedule schedule;

  Color get _own => Color(schedule.colorValue);

  @override
  Color picked(AppThemeColors colors) => colors.pickedShift(schedule.id, _own);

  @override
  Color resolved(AppThemeColors colors) => colors.shift(schedule.id, _own);

  @override
  bool isChanged(AppThemeColors colors) =>
      colors.shifts.containsKey(schedule.id);

  @override
  AppThemeColors apply(AppThemeColors colors, Color? color) =>
      colors.withShiftColor(schedule.id, color);

  @override
  String label({required bool isRu}) => schedule.organizationName;

  @override
  bool operator ==(Object other) =>
      other is ThemeShiftTarget && other.schedule.id == schedule.id;

  @override
  int get hashCode => schedule.id.hashCode;

  @override
  String toString() => 'shift_${schedule.id}';
}
