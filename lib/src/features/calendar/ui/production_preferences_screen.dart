import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/ui/memory_card/sticker_paper.dart';
import '../../../shared/ui/screen_chrome.dart';
import '../../settings/settings.dart';
import '../state/production_preferences.dart';

/// Что показывать из производственного календаря: плитками, как настройки.
class ProductionPreferencesScreen extends ConsumerWidget {
  const ProductionPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final settings = ref.watch(productionPreferencesProvider);
    final controller = ref.read(productionPreferencesProvider.notifier);

    SettingsTile tile(
      String key,
      IconData icon,
      Color color,
      String title,
      bool value,
      VoidCallback onTap,
    ) =>
        SettingsTile(
          key: ValueKey(key),
          icon: icon,
          color: color,
          title: title,
          lit: value,
          toggled: value,
          trailing: SettingsToggle(value: value),
          onTap: onTap,
        );

    return Scaffold(
      appBar: AppPageAppBar(
        fallbackLocation: '/settings',
        title: Text(
          strings.productionCalendar,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        hint: strings.productionSettingsHint,
      ),
      body: WarmGradientBackground(
        child: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  StickerPaper.gridEdge,
                  8,
                  StickerPaper.gridEdge,
                  24,
                ),
                children: [
                  SettingsSection(
                    children: [
                      tile(
                        'production_highlight_setting',
                        Icons.format_color_fill_rounded,
                        AppPalette.cyan,
                        strings.productionHighlight,
                        settings.highlight,
                        () => controller.update(highlight: !settings.highlight),
                      ),
                      tile(
                        'production_weeks_setting',
                        Icons.tag_rounded,
                        AppPalette.indigo,
                        strings.productionWeekNumbers,
                        settings.weekNumbers,
                        () => controller.update(
                          weekNumbers: !settings.weekNumbers,
                        ),
                      ),
                      tile(
                        'production_progress_setting',
                        Icons.donut_large_rounded,
                        AppPalette.turquoise,
                        strings.productionShowProgress,
                        settings.showProgress,
                        () => controller.update(
                          showProgress: !settings.showProgress,
                        ),
                      ),
                      tile(
                        'production_today_setting',
                        Icons.today_rounded,
                        AppPalette.amber,
                        strings.productionIncludeToday,
                        settings.includeToday,
                        () => controller.update(
                          includeToday: !settings.includeToday,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
