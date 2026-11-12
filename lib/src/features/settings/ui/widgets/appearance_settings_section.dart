import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/locale/app_locale_controller.dart';
import '../../../../app/theme/app_content_font_controller.dart';
import '../../../../app/theme/app_theme_controller.dart';
import '../../../../platform/windows/windows_startup_controller.dart';
import '../../../../shared/state/app_hints_provider.dart';
import 'content_font_picker_sheet.dart';
import 'settings_chevron.dart';
import 'settings_language_mark.dart';
import 'settings_section.dart';
import 'settings_switch_tile.dart';
import 'settings_theme_tile.dart';
import 'settings_tile.dart';
import 'windows_startup_tile.dart';

/// Как выглядит приложение: тема, шрифт записей, язык и подсказки.
class AppearanceSettingsSection extends ConsumerWidget {
  const AppearanceSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final locale = ref.watch(appLocaleControllerProvider);
    final isRu = locale.languageCode == 'ru';
    final current = ref.watch(appThemeControllerProvider);
    final contentFont = ref.watch(appContentFontControllerProvider);
    final windowsPlatform = ref.watch(windowsDesktopPlatformProvider);

    return SettingsSection(
      title: strings.appearance,
      children: [
        for (final style in AppThemeStyle.available)
          SettingsThemeTile(
            style: style,
            selected: style == current,
            isRu: isRu,
            onTap: () => _setTheme(ref, style),
          ),
        SettingsTile(
          icon: Icons.font_download_rounded,
          color: AppPalette.violet,
          title: isRu ? 'Шрифт записей' : 'Record font',
          subtitle: contentFont.label,
          trailing: const SettingsChevron(),
          onTap: () => _pickFont(context, ref, contentFont, isRu),
        ),
        SettingsTile(
          key: const ValueKey('settings_language'),
          icon: Icons.language_rounded,
          color: AppPalette.cyan,
          title: strings.language,
          subtitle: isRu ? 'Русский' : 'English',
          trailing: SettingsLanguageMark(code: locale.languageCode),
          onTap: () => _toggleLocale(ref, isRu),
        ),
        SettingsSwitchTile(
          icon: Icons.tips_and_updates_rounded,
          color: AppPalette.amber,
          title: isRu ? 'Показывать подсказки' : 'Show hints',
          subtitle: isRu ? 'Кнопка «?» в шапке' : 'The “?” header button',
          setting: appHintsProvider,
        ),
        if (windowsPlatform.isSupported)
          WindowsStartupTile(
            state: ref.watch(windowsStartupControllerProvider),
          ),
      ],
    );
  }

  void _toggleLocale(WidgetRef ref, bool isRu) {
    final controller = ref.read(appLocaleControllerProvider.notifier);
    isRu ? controller.setEnglish() : controller.setRussian();
  }

  Future<void> _setTheme(WidgetRef ref, AppThemeStyle style) async {
    try {
      await NotebookAssets.preloadCurrent(
        dark: brightnessOf(style) == Brightness.dark,
      );
    } catch (_) {
      // Без картинок бумаги тема останется плоским цветом.
    }
    await ref.read(appThemeControllerProvider.notifier).setStyle(style);
  }

  Future<void> _pickFont(
    BuildContext context,
    WidgetRef ref,
    AppContentFontStyle current,
    bool isRu,
  ) async {
    final selected = await showContentFontPickerSheet(
      context: context,
      selected: current,
      isRu: isRu,
    );
    if (selected == null || !context.mounted) return;
    await ref
        .read(appContentFontControllerProvider.notifier)
        .setStyle(selected);
  }
}
