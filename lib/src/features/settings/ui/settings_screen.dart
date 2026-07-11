import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_locale_controller.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared/ui/screen_chrome.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final locale = ref.watch(appLocaleControllerProvider);
    final isRu = locale.languageCode == 'ru';

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
                    ],
                  ),
                  const SizedBox(height: 18),
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
                  const SizedBox(height: 18),
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
                        iconColor: const Color(0xFF2563EB),
                        title: strings.backup,
                        subtitle: strings.backupSubtitle,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go('/settings/backup'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
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
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFDED8CF)),
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                for (var index = 0; index < children.length; index++) ...[
                  if (index > 0)
                    const Divider(
                      height: 1,
                      indent: 64,
                      color: Color(0xFFE7E1D9),
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
    return ListTile(
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
              color: const Color(0xFF172033),
              fontWeight: FontWeight.w800,
            ),
      ),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
