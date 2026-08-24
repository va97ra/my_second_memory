/// Готовый рисунок графика смен.
///
/// Это данные: добавить вариант — добавить запись в [shiftPresets], ничего
/// больше не трогая.
class ShiftPreset {
  const ShiftPreset({
    required this.key,
    required this.ruLabel,
    required this.enLabel,
    required this.workDays,
    required this.restDays,
  });

  final String key;
  final String ruLabel;
  final String enLabel;
  final int workDays;
  final int restDays;

  String label(String languageCode) =>
      languageCode == 'ru' ? ruLabel : enLabel;
}

/// Рисунки графиков, которые предлагаются вместо ручного ввода.
const shiftPresets = <ShiftPreset>[
  ShiftPreset(
    key: '5/2',
    ruLabel: '5/2',
    enLabel: '5/2',
    workDays: 5,
    restDays: 2,
  ),
  ShiftPreset(
    key: '2/2',
    ruLabel: '2/2',
    enLabel: '2/2',
    workDays: 2,
    restDays: 2,
  ),
  ShiftPreset(
    key: '1/3',
    ruLabel: 'сутки/трое',
    enLabel: '24h/3 off',
    workDays: 1,
    restDays: 3,
  ),
];

/// Готовый рисунок с такими днями, или null, если это ручной график.
ShiftPreset? shiftPresetFor(int workDays, int restDays) {
  for (final preset in shiftPresets) {
    if (preset.workDays == workDays && preset.restDays == restDays) {
      return preset;
    }
  }
  return null;
}

/// Сутки через трое — единственный рисунок, где смена переходит через
/// полночь, поэтому только в нём будильник можно поставить на следующий день.
bool supportsNextDayAlarm(int workDays, int restDays) =>
    workDays == 1 && restDays == 3;

/// График всегда держит два будильника: на начало смены и на её конец.
/// Недостающие добавляются пустыми, чтобы форма не зависела от того, сколько
/// их сохранилось от прошлых версий.
int get shiftAlarmSlots => 2;
