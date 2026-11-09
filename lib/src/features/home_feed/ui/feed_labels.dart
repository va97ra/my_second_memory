import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../state/feed_providers.dart';

/// Подписи ленты: период на странице и разделители групп.
///
/// Все они собраны здесь, потому что одну и ту же дату лента показывает в трёх
/// местах и подписи должны совпадать.

/// Период, лежащий на странице. У записок периода нет.
String feedPeriodLabel(BuildContext context, FeedViewState view) {
  if (view.allDates) return AppStrings.of(context).allDates;
  final locale = Localizations.localeOf(context).languageCode;
  final formatted = switch (view.filter.recurringFrequency) {
    null => DateFormat.yMMMMEEEEd(locale).format(view.anchorDate),
    RecurrenceFrequency.monthly =>
      DateFormat.yMMMM(locale).format(view.anchorDate),
    RecurrenceFrequency.yearly => locale == 'ru'
        ? '${view.anchorDate.year} год'
        : '${view.anchorDate.year}',
  };
  return _capitalize(formatted);
}

/// Подпись разделителя внутри раскрытого периода.
String feedGroupLabel(BuildContext context, FeedFilter filter, DateTime period,
    {bool allDates = false}) {
  if (allDates) return feedFullDayLabel(context, period);
  final locale = Localizations.localeOf(context).languageCode;
  final value = filter.recurringFrequency == RecurrenceFrequency.yearly
      ? DateFormat.MMMM(locale).format(period)
      : DateFormat(locale == 'ru' ? 'd MMMM, EEEE' : 'EEEE, MMMM d', locale)
          .format(period);
  return _capitalize(value);
}

/// День полностью, с годом: среди всех дат год бывает и не текущий.
String feedFullDayLabel(BuildContext context, DateTime day) {
  final locale = Localizations.localeOf(context).languageCode;
  return _capitalize(DateFormat.yMMMMEEEEd(locale).format(day));
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return '${value[0].toUpperCase()}${value.substring(1)}';
}
