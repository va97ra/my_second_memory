import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../jarvis/jarvis.dart';
import 'gigachat_key_sheet.dart';
import 'jarvis_facts_sheet.dart';
import 'jarvis_settings_tiles.dart';
import 'settings_chevron.dart';
import 'settings_section.dart';
import 'settings_switch_tile.dart';
import 'settings_tile.dart';

/// Джарвис: нейросеть, которая понимает свободную речь, слух на имя, голос
/// напоминаний и сводки утром и вечером.
class JarvisSettingsSection extends ConsumerWidget {
  const JarvisSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final key = ref.watch(gigaChatKeyProvider);
    final connected = key.valueOrNull != null;
    final briefings = ref.watch(jarvisBriefingSettingsProvider);
    return SettingsSection(
      title: strings.jarvis,
      children: [
        SettingsTile(
          key: const ValueKey('settings_gigachat'),
          icon: Icons.psychology_rounded,
          title: strings.jarvisBrain,
          subtitle: key.hasError
              ? '${strings.jarvisBrainUnreadable}: ${key.error}'
              : connected
                  ? strings.jarvisBrainOn
                  : strings.jarvisBrainOff,
          trailing: const SettingsChevron(),
          onTap: () => showGigaChatKeySheet(context),
        ),
        SettingsTile(
          key: const ValueKey('settings_jarvis_facts'),
          icon: Icons.auto_stories_rounded,
          title: strings.jarvisFacts,
          subtitle:
              strings.jarvisFactsCount(ref.watch(jarvisFactsProvider).length),
          trailing: const SettingsChevron(),
          onTap: () => showJarvisFactsSheet(context),
        ),
        SettingsSwitchTile(
          key: const ValueKey('settings_jarvis_wake'),
          icon: Icons.record_voice_over_rounded,
          title: strings.jarvisWakeWord,
          subtitle: strings.jarvisWakeWordHint,
          setting: jarvisWakeEnabledProvider,
        ),
        SettingsSwitchTile(
          key: const ValueKey('settings_jarvis_speak'),
          icon: Icons.campaign_rounded,
          title: strings.jarvisSpeakReminders,
          subtitle: strings.jarvisSpeakRemindersHint,
          setting: jarvisSpeakRemindersProvider,
        ),
        const BankNoticesTile(),
        BriefingTile(
          key: const ValueKey('settings_jarvis_morning'),
          icon: Icons.wb_sunny_rounded,
          title: strings.jarvisMorningBriefing,
          enabled: briefings.morning,
          at: briefings.morningAt,
          onChanged: ({enabled, at}) => ref
              .read(jarvisBriefingSettingsProvider.notifier)
              .setMorning(enabled: enabled, at: at),
        ),
        BriefingTile(
          key: const ValueKey('settings_jarvis_evening'),
          icon: Icons.nights_stay_rounded,
          title: strings.jarvisEveningBriefing,
          enabled: briefings.evening,
          at: briefings.eveningAt,
          onChanged: ({enabled, at}) => ref
              .read(jarvisBriefingSettingsProvider.notifier)
              .setEvening(enabled: enabled, at: at),
        ),
      ],
    );
  }
}
