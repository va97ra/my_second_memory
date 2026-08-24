import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Подписи карточки записи. Собраны здесь, потому что плотная и обычная
/// карточки показывают одно и то же и расходиться им нельзя.

/// Подпись завершённой записи, или null, если запись ещё не завершена.
String? memoryDoneLabel(BuildContext context, MemoryItem item) {
  if (!item.isDone) return null;
  if (item.type != MemoryType.payment) return AppStrings.of(context).completed;
  return Localizations.localeOf(context).languageCode == 'ru'
      ? 'Оплачено'
      : 'Paid';
}

/// Сумма платежа в рублях, без копеек.
String memoryAmountLabel(int amountMinor) {
  final roubles = NumberFormat.decimalPattern('ru').format(amountMinor ~/ 100);
  return '$roubles ₽';
}

/// Возраст в день рождения, посчитанный на год этой записи.
String memoryAgeLabel(BuildContext context, MemoryItem item) {
  final years = item.memoryDate.year - item.birthYear!;
  return Localizations.localeOf(context).languageCode == 'ru'
      ? '$years лет'
      : '$years years';
}

/// Высота плотной карточки ленты.
///
/// До полуторного масштаба текста карточка растёт мягко, дальше — заметно:
/// иначе крупный шрифт не помещается в две строки.
double denseFeedCardHeight(BuildContext context) {
  final scale = MediaQuery.textScalerOf(context).scale(1);
  if (scale <= 1.3) {
    return 76 + ((scale - 1).clamp(0.0, 0.3) * 40);
  }
  final largeTextProgress = ((scale - 1.3) / 0.7).clamp(0.0, 1.0);
  return 88 + largeTextProgress * 64;
}
