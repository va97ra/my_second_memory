import 'package:flutter/material.dart';

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
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: Tooltip(
        message: item.label,
        child: NotebookPressable(
          onTap: onTap,
          playClick: false,
          borderRadius: BorderRadius.circular(14),
          child: compact
              ? _inlineItem(navigationTheme, iconTheme, labelStyle)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 56,
                      height: 32,
                      decoration: BoxDecoration(
                        color: selected
                            ? navigationTheme.indicatorColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item.icon,
                        size: iconTheme.size,
                        color: iconTheme.color,
                      ),
                    ),
                    SizedBox(
                      height: 20,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child:
                              Text(item.label, maxLines: 1, style: labelStyle),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  /// Кнопка верхней панели: значок и подпись одной строкой на плашке.
  Widget _inlineItem(
    NavigationBarThemeData navigationTheme,
    IconThemeData iconTheme,
    TextStyle? labelStyle,
  ) {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 34,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? navigationTheme.indicatorColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 18, color: iconTheme.color),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(item.label, maxLines: 1, style: labelStyle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
