/// Дюйм, прочитанный как на рулетке: «1 1/2″», а не «1.5».
///
/// Сантехническая присоединительная резьба называется дробью, и человек,
/// который меряет рулеткой в сантиметрах, ищет глазами именно «три четверти».
/// Знаменатель — шестнадцатая: так размечены рулетка и ключ, а не так, как
/// удобнее делить.
library;

import 'decimal_input.dart';

/// Мельчайшее деление дюймовой шкалы.
const int inchFractionDenominator = 16;

/// Дюймы дробью. Знак «≈» стоит там, где округление до шестнадцатой
/// изменило число: 1 м — это не ровно 39 3/8″, и молчать об этом нельзя.
String formatInchFraction(
  double inches, {
  int denominator = inchFractionDenominator,
}) {
  if (!inches.isFinite) return '—';
  final absolute = inches.abs();
  // Дробь читают на длине человеческого размера. Дюймы в миле дробью не
  // меряют, и шестнадцатые там — не точность, а мусор в конце строки.
  if (absolute >= 1e6) return '${formatToolNumber(inches)}″';

  final ticks = (absolute * denominator).round();
  final whole = ticks ~/ denominator;
  var numerator = ticks % denominator;
  var scale = denominator;
  final divisor = _greatestCommonDivisor(numerator, scale);
  if (divisor > 1) {
    numerator ~/= divisor;
    scale ~/= divisor;
  }

  final sign = inches.isNegative && ticks != 0 ? '-' : '';
  final approximately = absolute * denominator == ticks ? '' : '≈';
  final body = switch ((whole, numerator)) {
    (0, 0) => '0',
    (0, _) => '$numerator/$scale',
    (_, 0) => '$whole',
    _ => '$whole $numerator/$scale',
  };
  return '$approximately$sign$body″';
}

/// Число из поля ввода, где дробь — такая же запись, как десятичная точка.
///
/// «3/4» и «1 1/2» человек набирает ровно так, как читает с фитинга; всё
/// остальное разбирает [parseToolNumber], чтобы правило про запятую и точку
/// осталось в одном месте.
double? parseFractionalNumber(String raw) {
  // Знаки, которые ставит сам показ: «≈» перед округлённой дробью и «″» после
  // неё. Прочитать обратно нужно ровно то, что человек видит в поле, — иначе
  // ответ конвертера нельзя поправить, не стерев его целиком. Кавычка с
  // клавиатуры принимается заодно: «3/4"» набирают именно так.
  final text = raw.trim().replaceAll(RegExp(r'^≈|[″"]$'), '').trim();
  final match = _fraction.firstMatch(text);
  if (match == null) return parseToolNumber(text);
  final denominator = int.parse(match.group(4)!);
  if (denominator == 0) return null;
  final value = int.parse(match.group(2) ?? '0') +
      int.parse(match.group(3)!) / denominator;
  return match.group(1) == '-' ? -value : value;
}

final RegExp _fraction = RegExp(r'^([+-]?)(?:(\d+)\s+)?(\d+)\s*/\s*(\d+)$');

int _greatestCommonDivisor(int a, int b) {
  var first = a;
  var second = b;
  while (second != 0) {
    final rest = first % second;
    first = second;
    second = rest;
  }
  return first;
}
