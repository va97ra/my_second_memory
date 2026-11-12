import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../navigation/page_turn_navigation.dart';
import '../../../calendar/calendar.dart';
import 'settings_chevron.dart';
import 'settings_section.dart';
import 'settings_switch_tile.dart';
import 'settings_tile.dart';

/// Что видно в календаре: праздники, производственный календарь и смены.
class CalendarSettingsSection extends ConsumerWidget {
  const CalendarSettingsSection({super.key, required this.isRu});

  final bool isRu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);

    return SettingsSection(
      title: isRu ? 'Календарь' : 'Calendar',
      children: [
        SettingsSwitchTile(
          icon: Icons.celebration_rounded,
          color: AppPalette.magenta,
          title: isRu ? 'Показывать праздники' : 'Show holidays',
          subtitle: isRu ? 'В сетке и на экране дня' : 'In the grid and day',
          setting: appHolidaysProvider,
        ),
        SettingsSwitchTile(
          icon: Icons.public_rounded,
          color: AppPalette.turquoise,
          title: isRu ? 'Международные дни' : 'International observances',
          subtitle: isRu ? 'Только на экране дня' : 'On the day view only',
          setting: appObservancesProvider,
          enabled: ref.watch(appHolidaysProvider),
        ),
        SettingsTile(
          icon: Icons.calendar_month_rounded,
          color: AppPalette.indigo,
          title: strings.productionCalendar,
          trailing: const SettingsChevron(),
          onTap: () => context.pageTurnPush('/calendar/preferences'),
        ),
        SettingsTile(
          icon: Icons.work_history_rounded,
          color: AppPalette.cyan,
          title: strings.shiftSchedules,
          trailing: const SettingsChevron(),
          onTap: () => context.pageTurnGo('/settings/shifts'),
        ),
      ],
    );
  }
}
