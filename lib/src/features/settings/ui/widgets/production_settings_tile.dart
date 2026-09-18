import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';
import '../../../../navigation/page_turn_navigation.dart';
import 'settings_tile.dart';
import 'settings_chevron.dart';

class ProductionSettingsTile extends StatelessWidget {
  const ProductionSettingsTile({super.key});
  @override
  Widget build(BuildContext context) => SettingsTile(
        icon: Icons.calendar_month_rounded,
        title: AppStrings.of(context).productionCalendar,
        trailing: const SettingsChevron(),
        onTap: () => context.pageTurnPush('/calendar/preferences'),
      );
}
