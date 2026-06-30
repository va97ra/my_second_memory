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
      child: ListView(
        children: [
          AppBar(title: Text(strings.settings)),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(strings.language),
            subtitle: Text(locale.languageCode == 'ru' ? 'Русский' : 'English'),
            trailing: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'ru', label: Text('RU')),
                ButtonSegment(value: 'en', label: Text('EN')),
              ],
              selected: {locale.languageCode},
              onSelectionChanged: (value) {
                final code = value.first;
                final controller = ref.read(appLocaleControllerProvider.notifier);
                if (code == 'ru') {
                  controller.setRussian();
                } else {
                  controller.setEnglish();
                }
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(strings.pinSecurity),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/security'),
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: Text(strings.memoryBase),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/memory'),
          ),
        ],
      ),
    );
  }
}
