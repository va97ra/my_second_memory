import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme_data_provider.dart';
import '../../../../navigation/page_turn_navigation.dart';
import 'settings_chevron.dart';
import 'settings_tile.dart';
import 'theme_style_label.dart';

/// Плитка темы: нарисована самой этой темой с выбранными для неё цветами,
/// поэтому она и есть образец. Нажатие открывает карточку темы, где её
/// включают и перекрашивают.
class SettingsThemeTile extends ConsumerWidget {
  const SettingsThemeTile({
    super.key,
    required this.style,
    required this.selected,
    required this.isRu,
  });

  final AppThemeStyle style;
  final bool selected;
  final bool isRu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = brightnessOf(style) == Brightness.dark;
    final theme = ref.watch(appThemeDataProvider(style));
    final accent = theme.colorScheme.primary;
    return Theme(
      data: theme,
      child: SettingsTile(
        key: ValueKey('settings_theme_${style.name}'),
        icon: dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
        color: accent,
        title: themeStyleLabel(style, isRu: isRu),
        subtitle: isRu ? 'Цвета' : 'Colours',
        selected: selected,
        trailing: selected
            ? Icon(Icons.check_circle_rounded, size: 20, color: accent)
            : const SettingsChevron(),
        onTap: () => context.pageTurnPush('/settings/theme/${style.name}'),
      ),
    );
  }
}
