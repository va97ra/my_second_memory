import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../jarvis/jarvis.dart';
import 'gigachat_key_sheet.dart';
import 'settings_chevron.dart';
import 'settings_section.dart';
import 'settings_tile.dart';

/// Джарвис: подключена ли нейросеть, которая понимает свободную речь.
class JarvisSettingsSection extends ConsumerWidget {
  const JarvisSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final connected = ref.watch(gigaChatKeyProvider).valueOrNull != null;
    return SettingsSection(
      title: strings.jarvis,
      children: [
        SettingsTile(
          key: const ValueKey('settings_gigachat'),
          icon: Icons.psychology_rounded,
          title: strings.jarvisBrain,
          subtitle: connected ? strings.jarvisBrainOn : strings.jarvisBrainOff,
          trailing: const SettingsChevron(),
          onTap: () => showGigaChatKeySheet(context),
        ),
      ],
    );
  }
}
