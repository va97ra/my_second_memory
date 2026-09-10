import 'package:flutter/material.dart';

import '../../themes/screen/screen_panel.dart';
import '../../themes/screen/screen_theme_colors.dart';
import 'nav_bar_item.dart';

/// Инструменты сверху там, где панели плавают: одна полоса стекла, а в ней
/// три кнопки — значок в цветном квадрате и подпись под ним.
///
/// Не три отдельные карточки: рамка вокруг каждой на светлом стекле спорила
/// с рамкой самой полосы, и верх читался стопкой белых прямоугольников. Цвет
/// у каждого инструмента свой и не зависит от того, выбран он сейчас или нет:
/// цвет здесь — имя, а не состояние. Выбранный подсвечивается подложкой того
/// же цвета.
class ScreenToolStrip extends StatelessWidget {
  const ScreenToolStrip({
    required this.items,
    required this.colors,
    required this.onSelected,
    this.selectedIndex,
    super.key,
  });

  final List<NavBarItem> items;
  final ScreenThemeColors colors;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  /// Высота полосы без системных полей: квадрат со значком, подпись и поля.
  static const double height = 74;

  static const double _squareSide = 36;

  @override
  Widget build(BuildContext context) {
    return ScreenPanel(
      colors: colors,
      edge: VerticalDirection.up,
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            for (var index = 0; index < items.length; index++)
              Expanded(
                child: _Tool(
                  key: ValueKey('top_${items[index].id}'),
                  item: items[index],
                  colors: colors,
                  tint: colors.toolTints[index % colors.toolTints.length],
                  selected: index == selectedIndex,
                  onTap: () => onSelected(index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Tool extends StatelessWidget {
  const _Tool({
    required this.item,
    required this.colors,
    required this.tint,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final NavBarItem item;
  final ScreenThemeColors colors;
  final Color tint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: Tooltip(
        message: item.label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: ScreenToolStrip._squareSide,
                  height: ScreenToolStrip._squareSide,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: selected ? 0.26 : 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(item.icon, size: 20, color: tint),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                      color: selected ? tint : colors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
