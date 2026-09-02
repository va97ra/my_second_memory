import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/locale/app_locale_controller.dart';
import '../../../navigation/page_turn_navigation.dart';
import '../../../shared/ui/screen_chrome.dart';
import '../../calendar/calendar.dart';
import 'widgets/app_settings_section.dart';
import 'widgets/data_settings_section.dart';
import 'widgets/feedback_request_card.dart';
import 'widgets/settings_section.dart';
import 'widgets/settings_tile.dart';
import './widgets/settings_chevron.dart';

/// Настройки: приложение, безопасность, данные.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final isRu = ref.watch(appLocaleControllerProvider).languageCode == 'ru';
    final showHints = ref.watch(appHintsProvider);

    return WarmGradientBackground(
      child: CustomScrollView(
        slivers: [
          MainSliverAppBar(title: strings.settings, backLocation: '/calendar'),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              child: Column(
                children: [
                  const AppSettingsSection(),
                  SettingsSection(
                    title: isRu ? 'Безопасность' : 'Security',
                    children: [
                      SettingsTile(
                        icon: Icons.lock_rounded,
                        title: strings.pinSecurity,
                        trailing: const SettingsChevron(),
                        onTap: () => context.pageTurnGo('/security'),
                      ),
                    ],
                  ),
                  DataSettingsSection(isRu: isRu),
                  if (showHints) ...[
                    const SizedBox(height: 12),
                    FeedbackRequestCard(isRu: isRu),
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
