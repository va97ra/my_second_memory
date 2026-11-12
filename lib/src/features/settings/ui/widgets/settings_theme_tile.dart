import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import 'settings_tile.dart';
import 'theme_style_label.dart';

/// Плитка темы: нарисована самой этой темой, поэтому она и есть образец.
class SettingsThemeTile extends StatelessWidget {
  const SettingsThemeTile({
    super.key,
    required this.style,
    required this.selected,
    required this.isRu,
    required this.onTap,
  });

  static final _themes = {
    for (final style in AppThemeStyle.available)
      style: buildNotebookTheme(brightness: brightnessOf(style)),
  };

  final AppThemeStyle style;
  final bool selected;
  final bool isRu;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = brightnessOf(style) == Brightness.dark;
    return Theme(
      data: _themes[style]!,
      child: SettingsTile(
        key: ValueKey('settings_theme_${style.name}'),
        icon: dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
        color: AppPalette.accent,
        title: themeStyleLabel(style, isRu: isRu),
        selected: selected,
        trailing: selected
            ? const Icon(
                Icons.check_circle_rounded,
                size: 20,
                color: AppPalette.accent,
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
