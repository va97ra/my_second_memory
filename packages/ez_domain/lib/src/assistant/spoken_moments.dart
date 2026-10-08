/// Время и дни так, как их говорят вслух.
///
/// Всё, что Джарвис произносит или пишет в подтверждении, называет время
/// словами: «в 2 часа дня», а не «в 14:00», — так говорят люди.
library;

import 'russian_numbers.dart';
import '../language/russian_plural.dart';

/// «полдень», «2 часа дня», «9 часов утра», «7:30 вечера».
String spokenClock(int minutes) {
  final hour = minutes ~/ 60 % 24;
  final minute = minutes % 60;
  if (hour == 12 && minute == 0) return 'полдень';
  if (hour == 0 && minute == 0) return 'полночь';
  final part = switch (hour) {
    < 5 => 'ночи',
    < 12 => 'утра',
    < 17 => 'дня',
    _ => 'вечера',
  };
  final shown = hour % 12 == 0 ? 12 : hour % 12;
  if (minute == 0) {
    return '$shown ${russianPlural(shown, 'час', 'часа', 'часов')} $part';
  }
  return '$shown:${minute.toString().padLeft(2, '0')} $part';
}

/// «в 2 часа дня», «в полдень».
String spokenAt(int minutes) => 'в ${spokenClock(minutes)}';

/// «сегодня», «завтра», «послезавтра», «вчера», «15 октября», «15 октября
/// 2027 года».
String spokenDay(DateTime day, DateTime now) {
  final difference = daysBetween(now, day);
  switch (difference) {
    case 0:
      return 'сегодня';
    case 1:
      return 'завтра';
    case 2:
      return 'послезавтра';
    case -1:
      return 'вчера';
  }
  return spokenDate(day, now);
}

/// «15 октября»; не этот год — «15 октября 2027 года».
String spokenDate(DateTime day, DateTime now) {
  final date = '${day.day} ${monthsGenitive[day.month - 1]}';
  return day.year == now.year ? date : '$date ${day.year} года';
}

/// «30 минут», «час», «2 часа», «1 час 30 минут».
String spokenDuration(int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  final hoursText = switch (hours) {
    0 => '',
    1 when rest == 0 => 'час',
    _ => '$hours ${russianPlural(hours, 'час', 'часа', 'часов')}',
  };
  final minutesText = rest == 0
      ? ''
      : '$rest ${russianPlural(rest, 'минуту', 'минуты', 'минут')}';
  return [hoursText, minutesText].where((part) => part.isNotEmpty).join(' ');
}

/// Сколько календарных дней от [from] до [to], без сбоя на переходе часов.
int daysBetween(DateTime from, DateTime to) =>
    DateTime.utc(to.year, to.month, to.day)
        .difference(DateTime.utc(from.year, from.month, from.day))
        .inDays;

const _weekdaysAccusative = [
  'в понедельник',
  'во вторник',
  'в среду',
  'в четверг',
  'в пятницу',
  'в субботу',
  'в воскресенье',
];

/// День так, как его называют, договариваясь: «сегодня», «завтра», «в
/// пятницу» — в пределах недели, дальше — «15 октября».
String spokenWhen(DateTime day, DateTime now) {
  final difference = daysBetween(now, day);
  if (difference >= 3 && difference <= 6) {
    return _weekdaysAccusative[day.weekday - 1];
  }
  return spokenDay(day, now);
}

/// «завтра в 10 часов утра», «в пятницу, весь день».
String spokenMoment(DateTime day, int? minutes, DateTime now) {
  final when = spokenWhen(day, now);
  return minutes == null ? '$when, весь день' : '$when ${spokenAt(minutes)}';
}
