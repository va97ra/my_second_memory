import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_locale_controller.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared/ui/app_shell.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final locale = ref.watch(appLocaleControllerProvider);

    return AppShell(
      currentIndex: 2,
      child: CustomScrollView(
        slivers: [
          SliverAppBar.large(title: Text(strings.settings)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDDE3EA)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.035),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: Icons.language,
                        iconColor: const Color(0xFF0891B2),
                        title: strings.language,
                        subtitle:
                            locale.languageCode == 'ru' ? 'Русский' : 'English',
                        trailing: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'ru', label: Text('RU')),
                            ButtonSegment(value: 'en', label: Text('EN')),
                          ],
                          selected: {locale.languageCode},
                          onSelectionChanged: (value) {
                            final code = value.first;
                            final controller =
                                ref.read(appLocaleControllerProvider.notifier);
                            if (code == 'ru') {
                              controller.setRussian();
                            } else {
                              controller.setEnglish();
                            }
                          },
                        ),
                      ),
                      const Divider(),
                      _SettingsTile(
                        icon: Icons.lock_outline,
                        iconColor: const Color(0xFF7C3AED),
                        title: strings.pinSecurity,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go('/security'),
                      ),
                      const Divider(),
                      _SettingsTile(
                        icon: Icons.inventory_2_outlined,
                        iconColor: const Color(0xFFEA580C),
                        title: strings.memoryBase,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go('/memory'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
      leading: DecoratedBox(
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, color: iconColor, size: 20),
        ),
      ),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
