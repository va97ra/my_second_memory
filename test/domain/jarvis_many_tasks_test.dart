import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

/// Несколько дел одной фразой на разные дни — как их диктуют вслух. Фразы
/// — те, на которых Джарвис ошибался у владельца (11 октября 2026).
void main() {
  final now = DateTime(2026, 10, 11, 10);

  List<(String, DateTime?, int?)> tasks(String phrase) {
    final command = const JarvisCommandParser().parse(phrase, now);
    expect(command, isA<CreateTasks>(), reason: phrase);
    return [
      for (final task in (command! as CreateTasks).tasks)
        (task.title, task.date, task.minutes),
    ];
  }

  test('новый день без запятой — новое дело', () {
    expect(
        tasks('запиши завтра в 10 врач в среду в 15 стоматолог '
            'и в пятницу забрать посылку'),
        [
          ('Врач', DateTime(2026, 10, 12), 600),
          ('Стоматолог', DateTime(2026, 10, 14), 900),
          ('Забрать посылку', DateTime(2026, 10, 16), null),
        ]);
  });

  test('запятые и «а» между днями', () {
    expect(tasks('завтра в 9 планёрка, послезавтра в 14 отчёт, а в субботу дача'), [
      ('Планёрка', DateTime(2026, 10, 12), 540),
      ('Отчёт', DateTime(2026, 10, 13), 840),
      ('Дача', DateTime(2026, 10, 17), null),
    ]);
    expect(tasks('в пятницу в 8 вечера кино а в воскресенье в 12 обед у родителей'),
        [
          ('Кино', DateTime(2026, 10, 16), 1200),
          ('Обед у родителей', DateTime(2026, 10, 18), 720),
        ]);
  });

  test('дело без своего дня — в день предыдущего', () {
    expect(tasks('завтра врач в 10 и стоматолог в 3'), [
      ('Врач', DateTime(2026, 10, 12), 600),
      ('Стоматолог', DateTime(2026, 10, 12), 900),
    ]);
  });

  test('перечисление покупок — одно дело', () {
    expect(tasks('запиши завтра купить хлеб, молоко и сыр, а послезавтра в 9 '
        'сдать отчёт'), [
      ('Купить хлеб, молоко и сыр', DateTime(2026, 10, 12), null),
      ('Сдать отчёт', DateTime(2026, 10, 13), 540),
    ]);
  });

  test('«в пятницу 16 октября» — один день, а не два дела', () {
    expect(tasks('запиши в пятницу 16 октября в 10 врач'),
        [('Врач', DateTime(2026, 10, 16), 600)]);
  });
}
