import 'package:ez_core/ez_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String records(int count) =>
      russianPlural(count, 'запись', 'записи', 'записей');

  test('последняя цифра выбирает форму', () {
    expect(records(1), 'запись');
    expect(records(2), 'записи');
    expect(records(4), 'записи');
    expect(records(5), 'записей');
    expect(records(0), 'записей');
  });

  test('одиннадцать — четырнадцать не подчиняются последней цифре', () {
    expect(records(11), 'записей');
    expect(records(12), 'записей');
    expect(records(14), 'записей');
    expect(records(21), 'запись');
    expect(records(112), 'записей');
    expect(records(122), 'записи');
  });
}
