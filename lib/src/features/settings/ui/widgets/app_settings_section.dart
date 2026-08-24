import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/locale/app_locale_controller.dart';
import '../../../../app/theme/app_content_font_controller.dart';
import '../../../../app/theme/app_theme_controller.dart';
import '../../../../platform/windows/windows_startup_controller.dart';
import '../../../calendar/calendar.dart';
import 'content_font_picker_sheet.dart';
import 'settings_section.dart';
import 'settings_tile.dart';
import 'theme_picker_sheet.dart';
import 'windows_startup_tile.dart';

/// Настройки самого приложения: язык, вид, шрифт записей и что показывать.
class AppSettingsSection extends ConsumerWidget {
  const AppSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final locale = ref.watch(appLocaleControllerProvider);
    final isRu = locale.languageCode == 'ru';
    final themeStyle = ref.watch(appThemeControllerProvider);
    final contentFont = ref.watch(appContentFontControllerProvider);
    final windowsPlatform = ref.watch(windowsDesktopPlatformProvider);

    return SettingsSection(
      title: isRu ? 'Приложение' : 'Application',
      children: [
        SettingsTile(
          icon: Icons.language_rounded,
          title: strings.language,
          subtitle: isRu ? 'Русский' : 'English',
          trailing: SegmentedButton<String>(
            // Подпись и так говорит, какой язык включён.
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 'ru', label: Text('RU')),
              ButtonSegment(value: 'en', label: Text('EN')),
            ],
            selected: {locale.languageCode},
            onSelectionChanged: (value) => _setLocale(ref, value.first),
          ),
        ),
        SettingsTile(
          icon: themeStyle.isDark
              ? Icons.dark_mode_rounded
              : Icons.light_mode_rounded,
          title: strings.appearance,
          subtitle: switch (themeStyle) {
            AppThemeStyle.notebookLight => strings.lightTheme,
            AppThemeStyle.notebookDark => strings.darkTheme,
          },
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _pickTheme(context, ref, themeStyle, isRu),
        ),
        SettingsTile(
          icon: Icons.font_download_rounded,
          title: isRu ? 'Шрифт записей' : 'Record font',
          subtitle: contentFont.label,
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _pickFont(context, ref, contentFont, isRu),
        ),
        SettingsTile(
          icon: Icons.tips_and_updates_rounded,
          title: isRu ? 'Показывать подсказки' : 'Show hints',
          subtitle: isRu
              ? 'Подсказки для новых пользователей'
              : 'Hints for new users',
          trailing: Switch(
            value: ref.watch(appHintsProvider),
            onChanged: ref.read(appHintsProvider.notifier).setEnabled,
          ),
        ),
        SettingsTile(
          icon: Icons.celebration_rounded,
          title: isRu ? 'Показывать праздники' : 'Show holidays',
          subtitle: isRu
              ? 'Праздники в календаре и экране дня'
              : 'Holidays in the calendar and day view',
          trailing: Switch(
            value: ref.watch(appHolidaysProvider),
            onChanged: ref.read(appHolidaysProvider.notifier).setEnabled,
          ),
        ),
        if (windowsPlatform.isSupported)
          WindowsStartupTile(
            state: ref.watch(windowsStartupControllerProvider),
          ),
      ],
    );
  }

  void _setLocale(WidgetRef ref, String languageCode) {
    final controller = ref.read(appLocaleControllerProvider.notifier);
    languageCode == 'ru' ? controller.setRussian() : controller.setEnglish();
  }

  Future<void> _pickTheme(
    BuildContext context,
    WidgetRef ref,
    AppThemeStyle current,
    bool isRu,
  ) async {
    final selected = await showThemePickerSheet(
      context: context,
      selected: current,
      isRu: isRu,
    );
    if (selected == null || !context.mounted) return;
    try {
      await NotebookAssets.preloadCurrent(dark: selected.isDark);
    } catch (_) {
      // Без картинок бумаги тема останется плоским цветом.
    }
    await ref.read(appThemeControllerProvider.notifier).setStyle(selected);
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
