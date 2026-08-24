import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/shift_schedule_form.dart';
import '../state/shift_schedules_controller.dart';
import 'widgets/labeled_switch_row.dart';
import 'widgets/shift_alarms_editor.dart';
import 'widgets/shift_color_picker.dart';
import 'widgets/shift_editor_header.dart';
import 'widgets/shift_editor_section.dart';
import 'widgets/shift_editor_sheet_shell.dart';
import 'widgets/shift_main_settings_fields.dart';
import 'widgets/shift_schedule_pattern_fields.dart';
import 'widgets/shift_vacation_list_editor.dart';

/// Редактор графика смен: нижний лист поверх списка графиков.
///
/// Лист владеет только полями ввода; всё выбранное живёт в
/// [ShiftScheduleForm] и потому проверяется без запуска этого листа.
class ShiftScheduleEditorSheet extends ConsumerStatefulWidget {
  const ShiftScheduleEditorSheet({super.key, this.schedule});

  final ShiftSchedule? schedule;

  @override
  ConsumerState<ShiftScheduleEditorSheet> createState() =>
      _ShiftScheduleEditorSheetState();
}

class _ShiftScheduleEditorSheetState
    extends ConsumerState<ShiftScheduleEditorSheet> {
  late final TextEditingController _organizationController;
  late final TextEditingController _workDaysController;
  late final TextEditingController _restDaysController;
  late ShiftScheduleForm _form;

  @override
  void initState() {
    super.initState();
    final schedule = widget.schedule;
    _organizationController = TextEditingController(
      text: schedule?.organizationName ?? '',
    );
    _workDaysController = TextEditingController(
      text: '${schedule?.workDays ?? ShiftScheduleForm.defaultWorkDays}',
    );
    _restDaysController = TextEditingController(
      text: '${schedule?.restDays ?? ShiftScheduleForm.defaultRestDays}',
    );
    _form = schedule == null
        ? ShiftScheduleForm.blank(DateTime.now())
        : ShiftScheduleForm.fromSchedule(schedule);
  }

  @override
  void dispose() {
    _organizationController.dispose();
    _workDaysController.dispose();
    _restDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context).languageCode;

    return ShiftEditorSheetShell(
      children: [
        ShiftEditorHeader(
          title: widget.schedule == null
              ? strings.addShiftSchedule
              : strings.editShiftSchedule,
        ),
        ShiftEditorSection(
          label: strings.mainSettings,
          child: ShiftMainSettingsFields(
            organizationController: _organizationController,
            startDate: _form.startDate,
            locale: locale,
            onStartDateChanged: (date) =>
                setState(() => _form = _form.withStartDate(date)),
          ),
        ),
        ShiftEditorSection(
          label: strings.scheduleSettings,
          child: ShiftSchedulePatternFields(
            selectedPresetKey: _form.presetKey,
            showManualSchedule: _form.showManualSchedule,
            workDaysController: _workDaysController,
            restDaysController: _restDaysController,
            locale: locale,
            onPreset: _applyPreset,
            onToggleManual: () =>
                setState(() => _form = _form.toggleManualSchedule()),
            onDaysChanged: _syncDays,
          ),
        ),
        ShiftEditorSection(
          label: strings.scheduleColor,
          bottomGap: 8,
          child: ShiftColorPicker(
            color: Color(_form.colorValue),
            onChanged: (color) => setState(
              () => _form = _form.withColorValue(color.toARGB32()),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: LabeledSwitchRow(
            icon: Icons.work_rounded,
            title: strings.enabled,
            value: _form.isEnabled,
            onChanged: (value) =>
                setState(() => _form = _form.withEnabled(value)),
          ),
        ),
        ShiftEditorSection(
          label: strings.vacations,
          child: ShiftVacationListEditor(
            vacations: _form.vacations,
            locale: locale,
            onAdd: (vacation) =>
                setState(() => _form = _form.withVacation(vacation)),
            onRemove: (id) => setState(() => _form = _form.withoutVacation(id)),
          ),
        ),
        ShiftEditorSection(
          label: strings.reminders,
          child: ShiftAlarmsEditor(
            alarms: _form.alarms,
            supportsNextDayAlarm: _supportsNextDayAlarm,
            onChanged: (alarms) =>
                setState(() => _form = _form.withAlarms(alarms)),
          ),
        ),
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_rounded),
            label: Text(strings.save),
          ),
        ),
      ],
    );
  }

  int? get _workDays => int.tryParse(_workDaysController.text.trim());

  int? get _restDays => int.tryParse(_restDaysController.text.trim());

  bool get _supportsNextDayAlarm =>
      supportsNextDayAlarmFor(_workDays ?? 0, _restDays ?? 0);

  void _applyPreset(ShiftPreset preset) {
    _workDaysController.text = '${preset.workDays}';
    _restDaysController.text = '${preset.restDays}';
    setState(() => _form = _form.withPreset(preset));
  }

  void _syncDays() {
    setState(() => _form = _form.withDays(_workDays, _restDays));
  }

  Future<void> _save() async {
    final schedule = _form.toSchedule(
      id: widget.schedule?.id,
      organizationName: _organizationController.text,
      workDays: _workDays,
      restDays: _restDays,
    );
    if (schedule == null) return;

    final controller = ref.read(shiftSchedulesControllerProvider.notifier);
    if (widget.schedule == null) {
      await controller.add(schedule);
    } else {
      await controller.update(schedule);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
