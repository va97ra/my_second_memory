import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'shift_schedule_form.dart';

/// Редактируемый график: поля ввода и всё выбранное.
///
/// Вынесен из экрана, потому что его читают и карточки, и листы настроек,
/// открытые поверх них. [updates] сообщает всем сразу.
class ShiftEditorDraft {
  ShiftEditorDraft(ShiftSchedule? schedule)
      : organization =
            TextEditingController(text: schedule?.organizationName ?? ''),
        workDaysField = TextEditingController(
          text: '${schedule?.workDays ?? ShiftScheduleForm.defaultWorkDays}',
        ),
        restDaysField = TextEditingController(
          text: '${schedule?.restDays ?? ShiftScheduleForm.defaultRestDays}',
        ),
        _form = ValueNotifier(
          schedule == null
              ? ShiftScheduleForm.blank(DateTime.now())
              : ShiftScheduleForm.fromSchedule(schedule),
        ) {
    updates = Listenable.merge([_form, workDaysField, restDaysField]);
  }

  final TextEditingController organization;
  final TextEditingController workDaysField;
  final TextEditingController restDaysField;
  final ValueNotifier<ShiftScheduleForm> _form;
  late final Listenable updates;

  ShiftScheduleForm get form => _form.value;
  set form(ShiftScheduleForm value) => _form.value = value;

  int? get workDays => int.tryParse(workDaysField.text.trim());
  int? get restDays => int.tryParse(restDaysField.text.trim());

  bool get supportsNextDayAlarm =>
      supportsNextDayAlarmFor(workDays ?? 0, restDays ?? 0);

  Iterable<ShiftAlarm> get enabledAlarms => form.alarms
      .take(supportsNextDayAlarm ? 2 : 1)
      .where((alarm) => alarm.isEnabled);

  void applyPreset(ShiftPreset preset) {
    workDaysField.text = '${preset.workDays}';
    restDaysField.text = '${preset.restDays}';
    form = form.withPreset(preset);
  }

  void syncDays() => form = form.withDays(workDays, restDays);

  /// Готовый график. Пусто, если форма заполнена не до конца.
  ShiftSchedule? toSchedule(String? id) => form.toSchedule(
        id: id,
        organizationName: organization.text,
        workDays: workDays,
        restDays: restDays,
      );

  String patternLabel(String locale) {
    for (final preset in shiftPresets) {
      if (preset.key == form.presetKey) return preset.label(locale);
    }
    return '${workDays ?? '–'}/${restDays ?? '–'}';
  }

  String vacationsLabel(AppStrings strings, String locale) {
    final vacations = form.vacations;
    if (vacations.isEmpty) return strings.noVacations;
    final format = DateFormat.MMMd(locale);
    final first = vacations.first;
    final range =
        '${format.format(first.startDate)} — ${format.format(first.endDate)}';
    return vacations.length == 1
        ? range
        : '$range · ${strings.moreVacations(vacations.length - 1)}';
  }

  String alarmsLabel(AppStrings strings) {
    final times = enabledAlarms.map((a) => formatMinutesOfDay(a.timeMinutes));
    return times.isEmpty ? strings.disabled : times.join(' · ');
  }

  void dispose() {
    organization.dispose();
    workDaysField.dispose();
    restDaysField.dispose();
    _form.dispose();
  }
}
