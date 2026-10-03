import 'app_strings.dart';

extension ProductionStrings on AppStrings {
  String get productionWeek => isRu ? 'Неделя' : 'Week';
  String get productionMonth => isRu ? 'Месяц' : 'Month';
  String get productionYear => isRu ? 'Год' : 'Year';
  String get productionElapsed => isRu ? 'Прошло' : 'Elapsed';
  String get productionRemaining => isRu ? 'Осталось' : 'Remaining';
  String get productionTotal => isRu ? 'Всего' : 'Total';
  String get productionDetails =>
      isRu ? 'Нормы и источник' : 'Norms and source';
  String get productionPlanNote =>
      isRu ? 'По графику, без отпуска' : 'Scheduled, excluding vacation';
  String get productionTodayIncluded =>
      isRu ? 'Включая сегодня' : 'Including today';
  String get productionTodayExcluded =>
      isRu ? 'Без сегодняшнего дня' : 'Excluding today';
  String get productionStatistics =>
      isRu ? 'Статистика работы' : 'Work statistics';
  String get productionFederal =>
      isRu ? 'Пятидневка РФ' : 'Russian five-day week';
  String get productionChooseSource => isRu
      ? 'Добавьте или включите график смен в настройках'
      : 'Add or enable a shift schedule in settings';

  String get shiftDayOff =>
      isRu ? 'Выходной по вашим графикам' : 'Day off on your schedules';
  String get shiftVacationDay =>
      isRu ? 'Отпуск · смена не учитывается' : 'Vacation · shift excluded';
  String shiftOrdinal(int number, int total) => isRu
      ? 'Смена $number из $total в этом месяце'
      : 'Shift $number of $total this month';
  String shiftDayProgress(int before, int after) => isRu
      ? 'По графику: до этой даты — $before, после — $after'
      : 'Scheduled shifts: before this date — $before, after — $after';

  String productionProgress(int passed, int total, int remaining,
          {String? source}) =>
      isRu
          ? '${source ?? '5/2'} · Прошло рабочих: $passed из $total · Осталось: $remaining'
          : '${source ?? '5/2'} · Elapsed: $passed of $total · Remaining: $remaining';
  String get productionProgressHint => isRu
      ? 'Плановый расчёт по выбранному графику, не табель явки. График и учёт сегодняшнего дня задаются в настройках.'
      : 'Planned shifts, not attendance. Enabled schedules apply automatically; configure whether to include today.';
  String get productionHighlight =>
      isRu ? 'Подсветка ячеек' : 'Highlight cells';
  String get productionWeekNumbers => isRu ? 'Номера недель' : 'Week numbers';
  String get productionShowProgress =>
      isRu ? 'Счётчик над календарём' : 'Progress above calendar';
  String get productionIncludeToday =>
      isRu ? 'Включать сегодняшний день' : 'Include today';
  String get productionSettingsHint => isRu
      ? 'Статистика автоматически учитывает включённые графики смен. Подсветка государственных выходных настраивается отдельно.'
      : 'Statistics automatically use enabled shift schedules. National day-off highlighting is independent.';
  String get productionCalendar =>
      isRu ? 'Производственный календарь' : 'Working calendar';
  String get productionScope => isRu
      ? 'Россия · пятидневка · федеральные нормы'
      : 'Russia · five-day week · federal rules';
  String get productionLegend => isRu
      ? 'Розовые ячейки — выходные; янтарные со * — дни короче на час. Слева — номера недель ISO. Личные смены и региональные праздники учитываются отдельно.'
      : 'Pink cells: days off; amber cells with *: one hour shorter. ISO week numbers are on the left. Personal shifts and regional holidays are separate.';
  String calendarWeek(int number, int year) =>
      isRu ? 'Неделя $number, $year год' : 'Week $number, $year';
  String get productionUnknown => isRu
      ? 'Данные за этот год недоступны.'
      : 'Data for this year is unavailable.';
  String productionDayLabel(String? kind) => switch (kind) {
        'working' => isRu ? 'Рабочий день' : 'Working day',
        'weekend' => isRu ? 'Выходной' : 'Weekend',
        'dayOff' => isRu ? 'Нерабочий день' : 'Day off',
        'holiday' => isRu ? 'Нерабочий праздник' : 'Public holiday',
        'transferredDayOff' =>
          isRu ? 'Перенесённый выходной' : 'Transferred day off',
        'shortened' =>
          isRu ? 'Сокращённый день · −1 час' : 'Shortened day · −1 hour',
        _ => productionUnknown,
      };
  String productionTotals(int work, int rest, int short) => isRu
      ? 'Рабочих дней: $work\nВыходных и праздничных: $rest\nСокращённых дней: $short'
      : 'Working days: $work\nDays off: $rest\nShortened days: $short';
  String productionHours(int week, String hours) =>
      isRu ? '$week ч/нед.: $hours ч' : '$week h/week: $hours h';
  String get productionSource => isRu
      ? 'Переносы: постановление Правительства РФ от 24.09.2025 № 1466; ст. 95, 112 ТК РФ.'
      : 'Transfers: Russian Government decree of 24 September 2025 No. 1466; Labour Code articles 95, 112.';
  String get productionApiSource => isRu
      ? 'Источник: isDayOff.ru — сторонний сервис по официальным данным.'
      : 'Source: isDayOff.ru — third-party service using official data.';
  String get productionBundled => isRu ? 'Встроенные данные' : 'Bundled data';
  String productionChecked(String date) =>
      isRu ? 'Обновлено: $date' : 'Updated: $date';
  String get productionUpdating =>
      isRu ? 'Обновляем календарь…' : 'Updating calendar…';
  String get productionUpdateFailed => isRu
      ? 'Не удалось получить обновление. Повторите позже.'
      : 'Could not fetch the update. Please try again later.';
  String get productionRefresh => isRu ? 'Обновить' : 'Refresh';
}
