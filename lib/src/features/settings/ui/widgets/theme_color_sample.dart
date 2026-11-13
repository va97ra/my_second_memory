import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import '../../../../shared/ui/memory_card/memory_item_presentation.dart';
import 'theme_color_target.dart';

/// Миниатюра того места, где меняется цвет: день календаря, кнопка или
/// карточка записи — нарисованные уже выбранным цветом.
class ThemeColorSample extends StatelessWidget {
  const ThemeColorSample({super.key, required this.target});

  final ThemeColorTarget target;

  static const _cell = 40.0;

  @override
  Widget build(BuildContext context) {
    final color = target.resolved(AppThemeColors.of(context));
    return Center(
      child: switch (target) {
        ThemeShiftTarget() => _day(header: color),
        ThemeRoleTarget(role: AppColorRole.today) => _day(ring: color),
        ThemeRoleTarget(role: AppColorRole.weekend) => _day(fill: color),
        ThemeRoleTarget(role: AppColorRole.shortenedDay) =>
          _day(fill: color, mark: '*'),
        ThemeRoleTarget(role: AppColorRole.accent) => _button(color),
        ThemeRoleTarget(:final type?) => _card(color, memoryTypeIcon(type)),
        ThemeRoleTarget() => const SizedBox.shrink(),
      },
    );
  }

  /// День календаря на бумаге: залитый, с шапкой смены или обведённый.
  Widget _day({Color? fill, Color? header, Color? ring, String mark = ''}) {
    final paper = fill ?? AppPalette.paperDay;
    return Container(
      width: _cell,
      height: _cell,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(4),
        border: ring == null ? null : Border.all(color: ring, width: 2.6),
        boxShadow: [
          if (ring != null)
            BoxShadow(color: ring.withValues(alpha: 0.6), blurRadius: 9),
        ],
      ),
      child: Column(
        children: [
          if (header != null) Container(height: _cell * 0.26, color: header),
          Expanded(
            child: Center(
              child: Text(
                '14$mark',
                style: TextStyle(
                  color: readableInkOn(paper),
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Кнопка и включённый переключатель — главные носители акцента.
  Widget _button(Color color) {
    final ink = readableInkOn(color);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.check_rounded, size: 16, color: ink),
        ),
        const SizedBox(width: 6),
        Container(
          width: 28,
          height: 16,
          padding: const EdgeInsets.all(2),
          alignment: Alignment.centerRight,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const DecoratedBox(
            decoration: BoxDecoration(
              color: AppPalette.paper,
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(dimension: 12),
          ),
        ),
      ],
    );
  }

  /// Карточка записи: цветная полоса сверху и значок вида.
  Widget _card(Color color, IconData icon) {
    return Container(
      width: _cell,
      height: _cell,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppPalette.paper,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(color: AppPalette.shadowSoft, blurRadius: 3),
        ],
      ),
      child: Column(
        children: [
          Container(height: 9, color: color),
          Expanded(child: Icon(icon, size: 18, color: color)),
        ],
      ),
    );
  }
}
