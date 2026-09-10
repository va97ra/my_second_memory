import 'package:flutter/material.dart';

import '../../themes/screen/screen_theme_colors.dart';
import '../../themes/screen/screen_visuals.dart';
import '../notebook_pressable.dart';
import 'nav_bar_item.dart';

/// Один ряд навигационных кнопок для обеих панелей оболочки.
class AppNavigationItems extends StatelessWidget {
  const AppNavigationItems({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.keyPrefix,
    required this.compact,
    super.key,
  });

  final List<NavBarItem> items;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;
  final String keyPrefix;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < items.length; index++)
          Expanded(
            child: _NavigationItemButton(
              key: ValueKey('${keyPrefix}_${items[index].id}'),
              item: items[index],
              selected: index == selectedIndex,
              compact: compact,
              onTap: () => onSelected(index),
            ),
          ),
      ],
    );
  }
}

class _NavigationItemButton extends StatelessWidget {
  const _NavigationItemButton({
    required this.item,
    required this.selected,
    required this.compact,
    required this.onTap,
    super.key,
  });

  final NavBarItem item;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navigationTheme = theme.navigationBarTheme;
    final states = <WidgetState>{
      if (selected) WidgetState.selected,
    };
    final iconTheme = navigationTheme.iconTheme?.resolve(states) ??
        const IconThemeData(size: 22);
    final labelStyle = navigationTheme.labelTextStyle?.resolve(states) ??
        theme.textTheme.labelSmall;
    final underlined = ScreenVisuals.maybeOf(context)?.colors.navIndicator ==
        ScreenNavIndicator.underline;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: Tooltip(
        message: item.label,
        child: NotebookPressable(
          onTap: onTap,
          playClick: false,
          pressedOffset: 1,
          borderRadius: BorderRadius.circular(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: compact ? 48 : 56,
                height: compact ? 28 : 32,
                decoration: BoxDecoration(
                  color: selected && !underlined
                      ? navigationTheme.indicatorColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  item.icon,
                  size: compact ? 20 : iconTheme.size,
                  color: iconTheme.color,
                ),
              ),
              SizedBox(
                height: compact ? 16 : 20,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(item.label, maxLines: 1, style: labelStyle),
                  ),
                ),
              ),
              // Полоса под подписью вместо подложки под значком: примета темы,
              // а не второй способ отметить одно и то же — тема выбирает одно
              // из двух.
              if (underlined)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  margin: const EdgeInsets.only(top: 3),
                  height: 2.5,
                  width: selected ? 26 : 0,
                  decoration: BoxDecoration(
                    color: labelStyle?.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
