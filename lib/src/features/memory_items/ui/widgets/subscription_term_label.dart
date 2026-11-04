import 'package:ez_core/ez_core.dart';

/// Срок подписки словами: «2 года 3 месяца» или «Без срока».
///
/// Нулевая часть не называется: «12 месяцев» — это «1 год», а не «1 год
/// 0 месяцев».
String subscriptionTermLabel(int? totalMonths, String locale) {
  if (totalMonths == null) return locale == 'ru' ? 'Без срока' : 'No end date';
  final years = totalMonths ~/ 12;
  final months = totalMonths % 12;
  final parts = <String>[];

  if (locale != 'ru') {
    if (years > 0) {
      parts.add('$years ${years == 1 ? 'year' : 'years'}');
    }
    if (months > 0) {
      parts.add('$months ${months == 1 ? 'month' : 'months'}');
    }
    return parts.join(' ');
  }

  if (years > 0) {
    parts.add('$years ${russianPlural(years, 'год', 'года', 'лет')}');
  }
  if (months > 0) {
    parts.add('$months ${russianPlural(months, 'месяц', 'месяца', 'месяцев')}');
  }
  return parts.join(' ');
}
