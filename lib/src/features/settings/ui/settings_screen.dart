import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_locale_controller.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme_controller.dart';
import '../../../core/theme/app_content_font.dart';
import '../../../core/theme/app_theme_style.dart';
import '../../../core/theme/notebook/notebook_assets.dart';
import '../../../core/theme/notebook/notebook_background.dart';
import '../../calendar/state/calendar_preferences_controller.dart';
import '../../../shared/ui/screen_chrome.dart';
import '../../../shared/ui/notebook_pressable.dart';
import 'widgets/theme_picker_sheet.dart';
import 'widgets/content_font_picker_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final locale = ref.watch(appLocaleControllerProvider);
    final isRu = locale.languageCode == 'ru';
    final themeStyle = ref.watch(appThemeControllerProvider);
    final contentFont = ref.watch(appContentFontControllerProvider);
    final showHints = ref.watch(appHintsProvider);
    final showHolidays = ref.watch(appHolidaysProvider);

    return WarmGradientBackground(
      child: CustomScrollView(
        slivers: [
          MainSliverAppBar(title: strings.settings, backLocation: '/'),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              child: Column(
                children: [
                  _SettingsSection(
                    title: isRu ? 'Приложение' : 'Application',
                    children: [
                      _SettingsTile(
                        icon: Icons.language,
                        iconColor: const Color(0xFF0891B2),
                        title: strings.language,
                        subtitle: isRu ? 'Русский' : 'English',
                        trailing: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'ru', label: Text('RU')),
                            ButtonSegment(value: 'en', label: Text('EN')),
                          ],
                          selected: {locale.languageCode},
                          onSelectionChanged: (value) {
                            final controller = ref.read(
                              appLocaleControllerProvider.notifier,
                            );
                            value.first == 'ru'
                                ? controller.setRussian()
                                : controller.setEnglish();
                          },
                        ),
                      ),
                      _SettingsTile(
                        icon: switch (themeStyle) {
                          AppThemeStyle.light => Icons.light_mode_outlined,
                          AppThemeStyle.dark => Icons.dark_mode_outlined,
                          AppThemeStyle.notebook => Icons.menu_book_outlined,
                        },
                        iconColor: Theme.of(context).colorScheme.primary,
                        title: strings.appearance,
                        subtitle: switch (themeStyle) {
                          AppThemeStyle.light => strings.lightTheme,
                          AppThemeStyle.dark => strings.darkTheme,
                          AppThemeStyle.notebook => strings.notebookTheme,
                        },
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final selected = await showThemePickerSheet(
                            context: context,
                            selected: themeStyle,
                            isRu: isRu,
                          );
                          if (selected != null && context.mounted) {
                            if (selected == AppThemeStyle.notebook) {
                              try {
                                await NotebookAssets.preload();
                              } catch (_) {
                                // The notebook theme has a gradient fallback.
                              }
                            }
                            await ref
                                .read(appThemeControllerProvider.notifier)
                                .setStyle(selected);
                          }
                        },
                      ),
                      _SettingsTile(
                        icon: Icons.font_download_outlined,
                        iconColor: const Color(0xFF7C3AED),
                        title: isRu ? 'Шрифт записей' : 'Record font',
                        subtitle: contentFont.label,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final selected = await showContentFontPickerSheet(
                            context: context,
                            selected: contentFont,
                            isRu: isRu,
                          );
                          if (selected != null && context.mounted) {
                            await ref
                                .read(appContentFontControllerProvider.notifier)
                                .setStyle(selected);
                          }
                        },
                      ),
                      _SettingsTile(
                        icon: Icons.tips_and_updates_outlined,
                        iconColor: const Color(0xFF0F766E),
                        title: isRu ? 'Показывать подсказки' : 'Show hints',
                        subtitle: isRu
                            ? 'Подсказки для новых пользователей'
                            : 'Hints for new users',
                        trailing: Switch(
                          value: showHints,
                          onChanged:
                              ref.read(appHintsProvider.notifier).setEnabled,
                        ),
                      ),
                      _SettingsTile(
                        icon: Icons.celebration_outlined,
                        iconColor: const Color(0xFFD97706),
                        title: isRu ? 'Показывать праздники' : 'Show holidays',
                        subtitle: isRu
                            ? 'Праздники в календаре и экране дня'
                            : 'Holidays in the calendar and day view',
                        trailing: Switch(
                          value: showHolidays,
                          onChanged:
                              ref.read(appHolidaysProvider.notifier).setEnabled,
                        ),
                      ),
                    ],
                  ),
                  _SettingsSection(
                    title: isRu ? 'Безопасность' : 'Security',
                    children: [
                      _SettingsTile(
                        icon: Icons.lock_outline,
                        iconColor: const Color(0xFF7C3AED),
                        title: strings.pinSecurity,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go('/security'),
                      ),
                    ],
                  ),
                  _SettingsSection(
                    title: isRu ? 'Данные и планирование' : 'Data and planning',
                    children: [
                      _SettingsTile(
                        icon: Icons.work_history_outlined,
                        iconColor: const Color(0xFF16A34A),
                        title: strings.shiftSchedules,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go('/settings/shifts'),
                      ),
                      _SettingsTile(
                        icon: Icons.inventory_2_outlined,
                        iconColor: const Color(0xFFEA580C),
                        title: strings.memoryBase,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go('/memory'),
                      ),
                      _SettingsTile(
                        icon: Icons.backup_outlined,
                        iconColor: Theme.of(context).colorScheme.primary,
                        title: strings.backup,
                        subtitle: strings.backupSubtitle,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go('/settings/backup'),
                      ),
                    ],
                  ),
                  if (showHints) ...[
                    const SizedBox(height: 12),
                    _FeedbackRequestCard(isRu: isRu),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackRequestCard extends StatelessWidget {
  const _FeedbackRequestCard({required this.isRu});

  final bool isRu;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: notebookSurfaceShadow(
          context,
          NotebookSurfaceDepth.card,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SizedBox(
                width: 38,
                height: 38,
                child: Icon(
                  Icons.rate_review_outlined,
                  color: colors.primary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRu
                        ? 'Помогите улучшить приложение'
                        : 'Help improve the app',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isRu
                        ? 'Напишите, что ещё вы хотите видеть в приложении. Если оно вам понравилось, пожалуйста, поставьте оценку в RuStore.'
                        : 'Tell us what else you would like to see. If you enjoy the app, please rate it in RuStore.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppLabeledDivider(
          label: title,
          padding: const EdgeInsets.fromLTRB(0, 3, 0, 3),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            boxShadow: notebookSurfaceShadow(
              context,
              NotebookSurfaceDepth.card,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                for (var index = 0; index < children.length; index++) ...[
                  if (index > 0)
                    Divider(
                      height: 1,
                      indent: 64,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  children[index],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tile = ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: DecoratedBox(
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: iconColor, size: 20),
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
      ),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing,
    );
    return NotebookPressable(onTap: onTap, child: tile);
  }
}
