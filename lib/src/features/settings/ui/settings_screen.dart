import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/locale/app_locale_controller.dart';
import '../../../shared/ui/memory_card/sticker_paper.dart';
import '../../../shared/ui/screen_chrome.dart';
import 'widgets/appearance_settings_section.dart';
import 'widgets/calendar_settings_section.dart';
import 'widgets/data_settings_section.dart';
import 'widgets/feedback_request_card.dart';

/// Настройки плитками: вид, календарь, защита и данные.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final isRu = ref.watch(appLocaleControllerProvider).languageCode == 'ru';

    return WarmGradientBackground(
      child: CustomScrollView(
        slivers: [
          MainSliverAppBar(
            title: strings.settings,
            backLocation: '/calendar',
            hint: strings.settingsPageHint,
          ),
          SliverToBoxAdapter(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    StickerPaper.gridEdge,
                    0,
                    StickerPaper.gridEdge,
                    20,
                  ),
                  child: Column(
                    children: [
                      const AppearanceSettingsSection(),
                      CalendarSettingsSection(isRu: isRu),
                      DataSettingsSection(isRu: isRu),
                      const SizedBox(height: StickerPaper.gridGap * 2),
                      FeedbackRequestCard(isRu: isRu),
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
