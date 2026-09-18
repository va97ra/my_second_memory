import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/ui/screen_chrome.dart';
import '../state/production_preferences.dart';

class ProductionPreferencesScreen extends ConsumerWidget {
  const ProductionPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final settings = ref.watch(productionPreferencesProvider);
    final controller = ref.read(productionPreferencesProvider.notifier);
    return Scaffold(
      appBar: AppPageAppBar(
          fallbackLocation: '/settings',
          title: Text(strings.productionCalendar,
              maxLines: 2, overflow: TextOverflow.ellipsis),
          hint: strings.productionSettingsHint),
      body: WarmGradientBackground(
          child: SafeArea(
              top: false,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: ListView(padding: const EdgeInsets.all(16), children: [
                    SwitchListTile(
                        key: const ValueKey('production_highlight_setting'),
                        title: Text(strings.productionHighlight),
                        value: settings.highlight,
                        onChanged: (v) => controller.update(highlight: v)),
                    SwitchListTile(
                        key: const ValueKey('production_weeks_setting'),
                        title: Text(strings.productionWeekNumbers),
                        value: settings.weekNumbers,
                        onChanged: (v) => controller.update(weekNumbers: v)),
                    SwitchListTile(
                        key: const ValueKey('production_progress_setting'),
                        title: Text(strings.productionShowProgress),
                        value: settings.showProgress,
                        onChanged: (v) => controller.update(showProgress: v)),
                    const SizedBox(height: 16),
                    SwitchListTile(
                        key: const ValueKey('production_today_setting'),
                        title: Text(strings.productionIncludeToday),
                        value: settings.includeToday,
                        onChanged: (v) => controller.update(includeToday: v)),
                  ]),
                ),
              ))),
    );
  }
}
