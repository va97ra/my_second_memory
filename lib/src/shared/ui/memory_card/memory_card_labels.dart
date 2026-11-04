import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Подписи карточки записи. Собраны здесь, потому что плотная и обычная
/// карточки показывают одно и то же и расходиться им нельзя.

/// Как называется вид записи на карточке: запись без даты — записка.
String memoryKindLabel(BuildContext context, MemoryItem item) => item.isUndated
    ? AppStrings.of(context).noteCard
    : item.type.label(Localizations.localeOf(context).languageCode);

/// Подпись завершённой записи, или null, если запись ещё не завершена.
String? memoryDoneLabel(BuildContext context, MemoryItem item) {
  if (!item.isDone) return null;
  if (item.type != MemoryType.payment) return AppStrings.of(context).completed;
  return Localizations.localeOf(context).languageCode == 'ru'
      ? 'Оплачено'
      : 'Paid';
}

/// Когда запись создана: день и месяц, а у прошлых лет ещё и год.
String memoryCreatedLabel(MemoryItem item) {
  final created = item.createdAt;
  return DateFormat(
    created.year == DateTime.now().year ? 'dd.MM' : 'dd.MM.yy',
  ).format(created);
}

/// День записи и её время, если оно есть.
String memoryDayAndTimeLabel(MemoryItem item) {
  final day = DateFormat('dd.MM').format(item.memoryDate);
  final time = item.timeMinutes;
  return time == null ? day : '$day ${formatMinutesOfDay(time)}';
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

