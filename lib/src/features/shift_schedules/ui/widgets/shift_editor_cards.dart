import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../shared/ui/memory_card/sticker_paper.dart';
import '../../../settings/settings.dart';
import '../../state/shift_editor_draft.dart';
import 'shift_alarms_editor.dart';
import 'shift_editor_sheet.dart';
import 'shift_name_band.dart';
import 'shift_schedule_pattern_fields.dart';
import 'shift_vacation_list_editor.dart';

/// Содержимое редактора графика: полоса с названием и карточки настроек.
class ShiftEditorCards extends StatelessWidget {
  const ShiftEditorCards({super.key, required this.draft, this.scheduleId});

  final ShiftEditorDraft draft;

  /// У нового графика id ещё нет, и цвет у него пока только свой.
  final String? scheduleId;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final form = draft.form;
    final own = Color(form.colorValue);
    final id = scheduleId;
    // Цвет графика выбирают в карточке темы, а здесь он только виден.
    final accent = id == null ? own : AppThemeColors.of(context).shift(id, own);
    const chevron = SettingsChevron();

    void open(String title, WidgetBuilder editor) => showShiftEditorSheet(
          context,
          title: title,
          updates: draft.updates,
          builder: editor,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ShiftNameBand(controller: draft.organization, color: accent),
        const SizedBox(height: StickerPaper.gridGap),
        SettingsSection(
          children: [
            SettingsTile(
              key: const ValueKey('shift_tile_date'),
              icon: Icons.today_rounded,
              color: AppPalette.cyan,
              title: strings.startDate,
              subtitle: DateFormat.yMMMd(locale).format(form.startDate),
              trailing: chevron,
              onTap: () => _pickStartDate(context),
            ),
            SettingsTile(
              key: const ValueKey('shift_tile_pattern'),
              icon: Icons.work_history_rounded,
              color: AppPalette.indigo,
              title: strings.scheduleSettings,
              subtitle: draft.patternLabel(locale),
              trailing: chevron,
              onTap: () => open(strings.scheduleSettings, _patternEditor),
            ),
            SettingsTile(
              key: const ValueKey('shift_tile_enabled'),
              icon: Icons.power_settings_new_rounded,
              color: AppPalette.turquoise,
              title: strings.enabled,
              lit: form.isEnabled,
              toggled: form.isEnabled,
              trailing: SettingsToggle(value: form.isEnabled),
              onTap: () => draft.form = form.withEnabled(!form.isEnabled),
            ),
            SettingsTile(
              key: const ValueKey('shift_tile_vacations'),
              icon: Icons.beach_access_rounded,
              color: AppPalette.vacationCloth,
              title: strings.vacations,
              subtitle: draft.vacationsLabel(strings, locale),
              lit: form.vacations.isNotEmpty,
              trailing: chevron,
              onTap: () => open(strings.vacations, _vacationsEditor),
            ),
            SettingsTile(
              key: const ValueKey('shift_tile_alarms'),
              icon: Icons.alarm_rounded,
              color: Theme.of(context).colorScheme.primary,
              title: strings.shiftAlarm,
              subtitle: draft.alarmsLabel(strings),
              lit: draft.enabledAlarms.isNotEmpty,
              trailing: chevron,
              onTap: () => open(strings.shiftAlarm, _alarmsEditor),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: draft.form.startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) draft.form = draft.form.withStartDate(picked);
  }

  Widget _patternEditor(BuildContext context) => ShiftSchedulePatternFields(
        selectedPresetKey: draft.form.presetKey,
        showManualSchedule: draft.form.showManualSchedule,
        workDaysController: draft.workDaysField,
        restDaysController: draft.restDaysField,
        locale: Localizations.localeOf(context).languageCode,
        onPreset: draft.applyPreset,
        onToggleManual: () => draft.form = draft.form.toggleManualSchedule(),
        onDaysChanged: draft.syncDays,
      );

  Widget _vacationsEditor(BuildContext context) => ShiftVacationListEditor(
        vacations: draft.form.vacations,
        locale: Localizations.localeOf(context).languageCode,
        onAdd: (vacation) => draft.form = draft.form.withVacation(vacation),
        onRemove: (id) => draft.form = draft.form.withoutVacation(id),
      );

  Widget _alarmsEditor(BuildContext context) => ShiftAlarmsEditor(
        alarms: draft.form.alarms,
        supportsNextDayAlarm: draft.supportsNextDayAlarm,
        onChanged: (alarms) => draft.form = draft.form.withAlarms(alarms),
      );
}
