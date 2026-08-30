import 'package:flutter/material.dart';

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
      if (!item.enabled) WidgetState.disabled,
    };
    final iconTheme = navigationTheme.iconTheme?.resolve(states) ??
        const IconThemeData(size: 22);
    final labelStyle = navigationTheme.labelTextStyle?.resolve(states) ??
        theme.textTheme.labelSmall;
    return Semantics(
      button: true,
      selected: selected,
      enabled: item.enabled,
      label: item.label,
      child: Tooltip(
        message: item.label,
        child: InkWell(
          onTap: item.enabled ? onTap : null,
          child: Opacity(
            opacity: item.enabled ? 1 : 0.62,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: compact ? 48 : 56,
                  height: compact ? 28 : 32,
                  decoration: BoxDecoration(
                    color: selected
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
