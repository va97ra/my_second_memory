import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

/// Конвертер голосом: переводит сам конвертер, Джарвис его заполняет и
/// продолжает — «а в метрах?», «а если 10?», «поменяй местами».
void main() {
  final now = DateTime(2099, 10, 7, 14);
  JarvisCommand? parse(String phrase) =>
      const JarvisCommandParser().parse(phrase, now);

  ConverterCommand? next(String phrase) {
    final command = parse(phrase);
    return command is ConverterCommand ? command : null;
  }

  test('«на конвертере» — лишние слова, переводит всегда он', () {
    final command = parse('переведи 5 футов в метры на конвертере');
    expect(command, isA<ConvertUnits>());
    final asked = command as ConvertUnits;
    expect((asked.fromUnit, asked.toUnit, asked.value), ('foot', 'm', 5));
  });

  test('другая единица ответа', () {
    for (final phrase in [
      'а в сантиметрах',
      'переведи в сантиметры',
      'а в сантиметрах сколько будет'
    ]) {
      final command = next(phrase);
      expect(command?.move, ConverterMove.retarget, reason: phrase);
      expect(command?.unit, 'cm', reason: phrase);
      expect(command?.category, UnitCategory.length, reason: phrase);
    }
  });

  test('другое число', () {
    expect(next('а если 10')?.move, ConverterMove.revalue);
    expect(next('а если 10')?.value, 10);
    expect(next('а если 10')?.unit, isNull);
    final feet = next('а 10 футов');
    expect((feet?.move, feet?.value, feet?.unit),
        (ConverterMove.revalue, 10, 'foot'));
  });

  test('поменять местами', () {
    expect(next('поменяй местами')?.move, ConverterMove.swap);
    expect(next('наоборот')?.move, ConverterMove.swap);
  });

  test('часы и минуты из дел конвертер не забирает', () {
    expect(next('в 3 часа'), isNull);
    expect(next('на 10 минут'), isNull);
    expect(next('а в пятницу'), isNull);
    expect(parse('таймер на 10 минут'), isA<PhoneTimer>());
  });

  test('единица без русского слова — обозначением', () {
    const asked = ConvertUnits(
        value: 2, category: UnitCategory.length, fromUnit: 'm', toUnit: 'cm');
    expect(unitReply(asked, 200), '2 метра — это 200 сантиметров.');
  });
}
