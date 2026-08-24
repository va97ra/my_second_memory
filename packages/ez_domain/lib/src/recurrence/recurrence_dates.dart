/// Арифметика дат, на которой стоят повторы и календарь.
///
/// Всё здесь работает с днями, а не с моментами: у записи есть дата, а
/// время суток живёт отдельным полем.
library;

DateTime safeDate(int year, int month, int day) {
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, day > lastDay ? lastDay : day);
}

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Дата одним числом вида 20260824: по нему сравнивают и раскладывают дни,
/// не заводя объектов.
int dateKey(DateTime value) =>
    value.year * 10000 + value.month * 100 + value.day;

/// Дата обратно из ключа.
DateTime dateFromKey(int key) =>
    DateTime(key ~/ 10000, (key ~/ 100) % 100, key % 100);

DateTime latestDate(DateTime left, DateTime right) =>
    left.isAfter(right) ? left : right;

DateTime earliestDate(DateTime left, DateTime right) =>
    left.isBefore(right) ? left : right;

/// Даты повторов начиная со следующей после [reference] и до горизонта.
///
/// [after] сдвигает начало: так продолжают ряд с даты, на которой он был
/// прерван. Первый день самой серии в ряд не входит — на нём стоит сама
/// запись, а не её повтор.
