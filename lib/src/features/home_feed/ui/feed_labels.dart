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
  final locale = Localizations.localeOf(context).languageCode;
  if (allDates) {
    return _capitalize(DateFormat.yMMMMEEEEd(locale).format(period));
  }
  final value = filter.recurringFrequency == RecurrenceFrequency.yearly
      ? DateFormat.MMMM(locale).format(period)
      : DateFormat(locale == 'ru' ? 'd MMMM, EEEE' : 'EEEE, MMMM d', locale)
          .format(period);
  return _capitalize(value);
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return '${value[0].toUpperCase()}${value.substring(1)}';
}
