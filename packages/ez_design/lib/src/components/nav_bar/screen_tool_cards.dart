import 'package:flutter/material.dart';

import '../../themes/screen/screen_theme_colors.dart';
import 'nav_bar_item.dart';
import 'screen_tool_glass_button.dart';

/// Инструменты сверху там, где панель приклеена к краю окна: три отдельные
/// карточки со значком в цветном квадрате и подписью под ним.
///
/// Не ряд значков, как в блокноте: там панель — край обложки, и кнопки на ней
/// плоские. Здесь панель — тёмное стекло, и инструмент читается плиткой,
/// которую видно раньше, чем прочитана подпись. Цвет у каждого свой и не
/// зависит от того, выбран он сейчас или нет: цвет здесь — имя, а не
/// состояние.
///
/// Тема с плавающими полосами берёт вместо этого `ScreenToolStrip`: там
/// рамка вокруг каждой карточки спорит с рамкой самой полосы.
class ScreenToolCards extends StatelessWidget {
  const ScreenToolCards({
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

  /// Высота ряда: квадрат со значком, подпись и поля вокруг.
  static const double height = 82;

  static const double _squareSide = 40;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        child: Row(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              if (index > 0) const SizedBox(width: 8),
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
    return ScreenToolGlassButton(
      item: item,
      colors: colors,
      tint: tint,
      selected: selected,
      onTap: onTap,
      iconSide: ScreenToolCards._squareSide,
    );
  }
}
