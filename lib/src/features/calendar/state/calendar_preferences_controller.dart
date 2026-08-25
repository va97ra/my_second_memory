import '../../../shared/state/bool_setting_controller.dart';

/// Подсказки для новых пользователей.
final appHintsProvider = boolSettingProvider(
  storageKey: 'calendar_hints_enabled_v1',
  initial: true,
);

/// Официальные праздники: лента в сетке месяца и карточка на экране дня.
final appHolidaysProvider = boolSettingProvider(
  storageKey: 'calendar_holidays_enabled_v1',
  initial: true,
);

/// Международные и неофициальные дни. Живут только на экране дня: ленты им не
/// положено — см. `HolidayOccurrence.isOfficial`.
final appObservancesProvider = boolSettingProvider(
  storageKey: 'calendar_observances_enabled_v1',
  initial: true,
);
