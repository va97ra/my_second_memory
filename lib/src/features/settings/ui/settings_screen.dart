import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import '../../../platform/windows/windows_startup_controller.dart';
import '../../calendar/state/calendar_preferences_controller.dart';
import '../../sync/state/sync_controller.dart';
import '../../../shared/ui/screen_chrome.dart';
import 'widgets/theme_picker_sheet.dart';
import 'widgets/content_font_picker_sheet.dart';
import '../../../app/theme/app_content_font_controller.dart';
import '../../../app/theme/app_theme_controller.dart';
import '../../../navigation/page_turn_navigation.dart';
import '../../../app/locale/app_locale_controller.dart';

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
    final syncEnabled = ref.watch(syncBackendConfigProvider).isConfigured;
    final syncState = syncEnabled
        ? ref.watch(syncControllerProvider)
        : const SyncState.unconfigured();
    final windowsPlatform = ref.watch(windowsDesktopPlatformProvider);
    final windowsStartup = windowsPlatform.isSupported
        ? ref.watch(windowsStartupControllerProvider)
        : null;

    return WarmGradientBackground(
      child: CustomScrollView(
        slivers: [
          MainSliverAppBar(title: strings.settings, backLocation: '/calendar'),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              child: Column(
                children: [
                  _SettingsSection(
                    title: isRu ? 'Приложение' : 'Application',
                    children: [
                      _SettingsTile(
                        icon: Icons.language_rounded,
                        title: strings.language,
                        subtitle: isRu ? 'Русский' : 'English',
                        trailing: SegmentedButton<String>(
                          // The label already says which one is on.
                          showSelectedIcon: false,
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
                        icon: themeStyle.isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        title: strings.appearance,
                        subtitle: switch (themeStyle) {
                          AppThemeStyle.notebookLight => strings.lightTheme,
                          AppThemeStyle.notebookDark => strings.darkTheme,
                        },
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () async {
                          final selected = await showThemePickerSheet(
                            context: context,
                            selected: themeStyle,
                            isRu: isRu,
                          );
                          if (selected != null && context.mounted) {
                            try {
                              await NotebookAssets.preloadCurrent(
                                dark: selected.isDark,
                              );
                            } catch (_) {
                              // Flat colour is the fallback.
                            }
                            await ref
                                .read(appThemeControllerProvider.notifier)
                                .setStyle(selected);
                          }
                        },
                      ),
                      _SettingsTile(
                        icon: Icons.font_download_rounded,
                        title: isRu ? 'Шрифт записей' : 'Record font',
                        subtitle: contentFont.label,
                        trailing: const Icon(Icons.chevron_right_rounded),
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
                        icon: Icons.tips_and_updates_rounded,
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
                        icon: Icons.celebration_rounded,
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
                      if (windowsStartup != null)
                        _SettingsTile(
                          icon: Icons.desktop_windows_rounded,
                          title: strings.launchWithWindows,
                          subtitle: strings.launchWithWindowsSubtitle,
                          trailing: windowsStartup.when(
                            data: (enabled) => Switch(
                              value: enabled,
                              onChanged: (value) async {
                                final saved = await ref
                                    .read(windowsStartupControllerProvider
                                        .notifier)
                                    .setEnabled(value);
                                if (!saved && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        strings.launchWithWindowsFailed,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                            loading: () => const SizedBox.square(
                              dimension: 48,
                              child: Center(
                                child: SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                            error: (_, __) => IconButton(
                              tooltip: strings.retry,
                              onPressed: ref
                                  .read(
                                      windowsStartupControllerProvider.notifier)
                                  .load,
                              icon: const Icon(Icons.refresh_rounded),
                            ),
                          ),
                        ),
                    ],
                  ),
                  _SettingsSection(
                    title: isRu ? 'Безопасность' : 'Security',
                    children: [
                      _SettingsTile(
                        icon: Icons.lock_rounded,
                        title: strings.pinSecurity,
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.pageTurnGo('/security'),
                      ),
                    ],
                  ),
                  _SettingsSection(
                    title: isRu ? 'Данные и планирование' : 'Data and planning',
                    children: [
                      _SettingsTile(
                        icon: Icons.work_history_rounded,
                        title: strings.shiftSchedules,
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.pageTurnGo('/settings/shifts'),
                      ),
                      _SettingsTile(
                        icon: Icons.inventory_2_rounded,
                        title: strings.memoryArchive,
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.pageTurnGo('/memory'),
                      ),
                      if (syncEnabled)
                        _SettingsTile(
                          icon: syncState.status == SyncStatus.syncing
                              ? Icons.sync_rounded
                              : Icons.cloud_sync_rounded,
                          title: strings.synchronization,
                          subtitle: _syncSubtitle(strings, syncState),
                          trailing: syncState.status == SyncStatus.syncing
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.pageTurnGo('/settings/sync'),
                        ),
                      _SettingsTile(
                        icon: Icons.cloud_upload_rounded,
                        title: strings.backup,
                        subtitle: strings.backupSubtitle,
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.pageTurnGo('/settings/backup'),
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

  String _syncSubtitle(AppStrings strings, SyncState state) {
    return switch (state.status) {
      SyncStatus.ready => strings.syncReady,
      SyncStatus.syncing => strings.syncInProgress,
      SyncStatus.unconfigured => strings.syncNotConfigured,
      SyncStatus.needsVault => strings.syncVaultPassword,
      SyncStatus.error => state.error ?? strings.synchronizationSubtitle,
      _ => strings.synchronizationSubtitle,
    };
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
                  Icons.rate_review_rounded,
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
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tile = ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      // Ink on paper, no badge: in this app a bordered square is a button,
      // and colour names a record type. A settings row is neither.
      leading: SizedBox(
        width: 40,
        height: 40,
        child: Icon(
          icon,
          size: 22,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
