import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/foundation.dart';

/// Состояние редактора графика смен: всё, что человек выбрал, кроме
/// набранного текста.
///
/// Название организации и числа дней живут в контроллерах полей ввода — ими
/// владеет Flutter. Всё остальное здесь, отдельно от экрана, и потому
/// проверяется без его запуска.
@immutable
class ShiftScheduleForm {
  const ShiftScheduleForm({
    required this.startDate,
    required this.colorValue,
    required this.isEnabled,
    required this.alarms,
    required this.vacations,
    this.presetKey,
    this.showManualSchedule = false,
  });

  /// Форма нового графика: пятидневка, сегодняшнее начало, цвет по умолчанию.
  factory ShiftScheduleForm.blank(DateTime today) {
    return ShiftScheduleForm._normalized(
      startDate: today,
      colorValue: defaultColorValue,
      isEnabled: true,
      alarms: const [],
      vacations: const [],
      workDays: defaultWorkDays,
      restDays: defaultRestDays,
    );
  }

  /// Форма существующего графика.
  factory ShiftScheduleForm.fromSchedule(ShiftSchedule schedule) {
    return ShiftScheduleForm._normalized(
      startDate: schedule.startDate,
      colorValue: schedule.colorValue,
      isEnabled: schedule.isEnabled,
      alarms: schedule.alarms,
      vacations: schedule.vacations,
      workDays: schedule.workDays,
      restDays: schedule.restDays,
    );
  }

  factory ShiftScheduleForm._normalized({
    required DateTime startDate,
    required int colorValue,
    required bool isEnabled,
    required List<ShiftAlarm> alarms,
    required List<ShiftVacation> vacations,
    required int workDays,
    required int restDays,
  }) {
    final presetKey = shiftPresetFor(workDays, restDays)?.key;
    return ShiftScheduleForm(
      startDate: _dateOnly(startDate),
      colorValue: colorValue,
      isEnabled: isEnabled,
      alarms: _paddedAlarms(alarms),
      vacations: _sorted(vacations),
      presetKey: presetKey,
      // Ручной ввод открыт ровно тогда, когда рисунок не совпал ни с одним
      // готовым: иначе человек не увидит, откуда взялись его числа.
      showManualSchedule: presetKey == null,
    );
  }

  static const defaultColorValue = 0xFF2F7DD1;
  static const defaultWorkDays = 5;
  static const defaultRestDays = 2;

  final DateTime startDate;
  final int colorValue;
  final bool isEnabled;
  final List<ShiftAlarm> alarms;
  final List<ShiftVacation> vacations;
  final String? presetKey;
  final bool showManualSchedule;

  /// Готовый рисунок вместо ручного ввода.
  ShiftScheduleForm withPreset(ShiftPreset preset) => copyWith(
        presetKey: preset.key,
        showManualSchedule: false,
        alarms: _alarmsFor(preset.workDays, preset.restDays),
      );

  /// Числа, набранные вручную. Незаполненное поле и рисунок, которого нет
  /// среди готовых, одинаково снимают выбор.
  ShiftScheduleForm withDays(int? workDays, int? restDays) {
    final key = workDays == null || restDays == null
        ? null
        : shiftPresetFor(workDays, restDays)?.key;
    return copyWith(
      presetKey: key,
      clearPresetKey: key == null,
      alarms: _alarmsFor(workDays ?? 0, restDays ?? 0),
    );
  }

  /// Открыть или закрыть ручной ввод. Открытый ввод снимает выбор рисунка.
  ShiftScheduleForm toggleManualSchedule() => copyWith(
        showManualSchedule: !showManualSchedule,
        clearPresetKey: !showManualSchedule,
      );

  ShiftScheduleForm withStartDate(DateTime value) =>
      copyWith(startDate: _dateOnly(value));

  ShiftScheduleForm withColorValue(int value) => copyWith(colorValue: value);

  ShiftScheduleForm withEnabled(bool value) => copyWith(isEnabled: value);

  ShiftScheduleForm withAlarms(List<ShiftAlarm> value) =>
      copyWith(alarms: _paddedAlarms(value));

  ShiftScheduleForm withVacation(ShiftVacation vacation) =>
      copyWith(vacations: _sorted([...vacations, vacation]));

  ShiftScheduleForm withoutVacation(String id) => copyWith(
        vacations: [
          for (final vacation in vacations)
            if (vacation.id != id) vacation,
        ],
      );

  /// График по форме — или `null`, если форма ещё не заполнена: без названия
  /// и без положительного числа рабочих дней сохранять нечего.
  ShiftSchedule? toSchedule({
    required String? id,
    required String organizationName,
    required int? workDays,
    required int? restDays,
  }) {
    final name = organizationName.trim();
    if (name.isEmpty ||
        workDays == null ||
        workDays <= 0 ||
        restDays == null ||
        restDays < 0) {
      return null;
    }

    return ShiftSchedule(
      id: id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      organizationName: name,
      colorValue: colorValue,
      startDate: startDate,
      workDays: workDays,
      restDays: restDays,
      isEnabled: isEnabled,
      alarms: List.unmodifiable(_alarmsFor(workDays, restDays)),
      vacations: List.unmodifiable(vacations),
    );
  }

  ShiftScheduleForm copyWith({
    DateTime? startDate,
    int? colorValue,
    bool? isEnabled,
    List<ShiftAlarm>? alarms,
    List<ShiftVacation>? vacations,
    String? presetKey,
    bool clearPresetKey = false,
    bool? showManualSchedule,
  }) {
    return ShiftScheduleForm(
      startDate: startDate ?? this.startDate,
      colorValue: colorValue ?? this.colorValue,
      isEnabled: isEnabled ?? this.isEnabled,
      alarms: alarms ?? this.alarms,
      vacations: vacations ?? this.vacations,
      presetKey: clearPresetKey ? null : presetKey ?? this.presetKey,
      showManualSchedule: showManualSchedule ?? this.showManualSchedule,
    );
  }

  /// Будильник на следующий день гаснет вместе с рисунком, который его
  /// допускал: иначе в сохранённом графике остаётся включённый будильник,
  /// которому неоткуда сработать.
  List<ShiftAlarm> _alarmsFor(int workDays, int restDays) {
    if (supportsNextDayAlarmFor(workDays, restDays)) {
      return alarms;
    }
    return [
      for (var index = 0; index < alarms.length; index++)
        index == 1 ? alarms[index].copyWith(isEnabled: false) : alarms[index],
    ];
  }

  static List<ShiftAlarm> _paddedAlarms(List<ShiftAlarm> alarms) {
    final padded = List.of(alarms);
    while (padded.length < shiftAlarmSlots) {
      padded.add(const ShiftAlarm());
    }
    return List.unmodifiable(padded);
  }

  static List<ShiftVacation> _sorted(List<ShiftVacation> vacations) {
    return List.unmodifiable(
      List.of(vacations)..sort((a, b) => a.startDate.compareTo(b.startDate)),
    );
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
