/// Согласование русского слова с числом.
///
/// Одиннадцать — двадцать не подчиняются последней цифре: «11 записей», но
/// «21 запись». Это правило языка, и оно записано здесь одно на всё
/// приложение: им пользуются и строки интерфейса, и речь Джарвиса.
String russianPlural(int value, String one, String few, String many) {
  final teens = value.abs() % 100;
  if (teens >= 11 && teens <= 14) return many;
  return switch (value.abs() % 10) {
    1 => one,
    2 || 3 || 4 => few,
    _ => many,
  };
}
