import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

/// Разбор фразы-дела. Случаи перенесены из MemoryVoice, где проверены на
/// телефоне владельца.
void main() {
  // Среда, 7 октября 2026, 14:00.
  final now = DateTime(2026, 10, 7, 14);
  const parser = TaskPhraseParser();
  int at(int hour, [int minute = 0]) => hour * 60 + minute;

  ParsedTask one(String text) => parser.parse(text, now).task;

  void expectTask(
    String text, {
    required String title,
    DateTime? date,
    int? minutes,
    bool confident = true,
  }) {
    final result = parser.parse(text, now);
    expect(result.task.title, title, reason: text);
    expect(result.task.date, date, reason: text);
    expect(result.task.minutes, minutes, reason: text);
    expect(result.confident, confident, reason: text);
  }

  group('примеры владельца', () {
    test('завтра без времени — спросить время', () {
      final task = one('завтра заплатить за счётчики');
      expect(task.title, 'Заплатить за счётчики');
      expect(task.date, DateTime(2026, 10, 8));
      expect(task.minutes, isNull);
      expect(task.need, TaskNeed.time);
    });

    test('«часов в 10» — «часов» не попадает в название', () {
      expectTask('надо бы встретиться с юристом в пятницу утром часов в 10',
          title: 'Встретиться с юристом',
          date: DateTime(2026, 10, 9),
          minutes: at(10));
      expect(one('завтра где-то в 5 забрать машину').title, 'Забрать машину');
    });

    test('«с днём рождения» — не время суток', () {
      final task = one('завтра поздравить маму с днём рождения');
      expect(task.date, DateTime(2026, 10, 8));
      expect(task.minutes, isNull);
      expect(one('поздравить маму с днём рождения').date, isNull);
      expect(one('завтра днём забрать посылку').minutes, isNotNull);
    });

    test('день недели и вечер', () {
      expectTask('в пятницу в 7 вечера позвонить маме',
          title: 'Позвонить маме',
          date: DateTime(2026, 10, 9),
          minutes: at(19));
    });

    test('через 2 часа', () {
      expectTask('через 2 часа выключить духовку',
          title: 'Выключить духовку',
          date: DateTime(2026, 10, 7),
          minutes: at(16));
    });

    test('дата с месяцем', () {
      expectTask('15 ноября день рождения Саши',
          title: 'День рождения Саши', date: DateTime(2026, 11, 15));
    });

    test('«в 3» без даты — сегодня в 15:00', () {
      expectTask('в 3 забрать посылку',
          title: 'Забрать посылку',
          date: DateTime(2026, 10, 7),
          minutes: at(15));
    });

    test('без даты — не уверен и спросит день', () {
      final result = parser.parse('купить молоко', now);
      expect(result.confident, isFalse);
      expect(result.task.title, 'Купить молоко');
      expect(result.task.need, TaskNeed.date);
    });
  });

  group('дни', () {
    test('слова и смещения', () {
      expectTask('сегодня вынести мусор',
          title: 'Вынести мусор', date: DateTime(2026, 10, 7));
      expectTask('Завтра Полить Цветы',
          title: 'Полить Цветы', date: DateTime(2026, 10, 8));
      expectTask('через 3 дня сдать отчёт',
          title: 'Сдать отчёт', date: DateTime(2026, 10, 10));
      expectTask('через неделю продлить страховку',
          title: 'Продлить страховку', date: DateTime(2026, 10, 14));
      expectTask('через месяц поменять фильтр',
          title: 'Поменять фильтр', date: DateTime(2026, 11, 7));
      expectTask('через пару дней позвонить Пете',
          title: 'Позвонить Пете', date: DateTime(2026, 10, 9));
    });

    test('дни недели', () {
      expectTask('в среду бассейн',
          title: 'Бассейн', date: DateTime(2026, 10, 14));
      expectTask('в следующую пятницу корпоратив',
          title: 'Корпоратив', date: DateTime(2026, 10, 16));
      expectTask('в эту субботу дача',
          title: 'Дача', date: DateTime(2026, 10, 10));
      expectTask(
          'слушай, напомни мне на следующей неделе в среду утром сходить к '
          'стоматологу',
          title: 'Сходить к стоматологу',
          date: DateTime(2026, 10, 14),
          minutes: at(9));
      expectTask('на выходных починить кран',
          title: 'Починить кран', date: DateTime(2026, 10, 10));
    });

    test('числа', () {
      expectTask('15.10 техосмотр',
          title: 'Техосмотр', date: DateTime(2026, 10, 15));
      expectTask('3 марта годовщина',
          title: 'Годовщина', date: DateTime(2027, 3, 3));
      expectTask('пятнадцатого октября концерт',
          title: 'Концерт', date: DateTime(2026, 10, 15));
      expectTask('20 числа заплатить за квартиру',
          title: 'Заплатить за квартиру', date: DateTime(2026, 10, 20));
      expectTask('5-го получить зарплату',
          title: 'Получить зарплату', date: DateTime(2026, 11, 5));
      expect(one('31 ноября что-то').date, isNull);
    });

    test('«на следующей неделе» без дня — не уверен', () {
      final result = parser.parse('на следующей неделе позвонить в банк', now);
      expect(result.confident, isFalse);
      expect(result.task.title, 'Позвонить в банк');
    });
  });

  group('время', () {
    test('часы и минуты', () {
      expectTask('завтра в 10:30 созвон',
          title: 'Созвон', date: DateTime(2026, 10, 8), minutes: at(10, 30));
      expectTask('завтра в 7 утра пробежка',
          title: 'Пробежка', date: DateTime(2026, 10, 8), minutes: at(7));
      expectTask('в пятницу в 3 дня стрижка',
          title: 'Стрижка', date: DateTime(2026, 10, 9), minutes: at(15));
      expectTask('завтра в 10 часов 15 минут встреча',
          title: 'Встреча', date: DateTime(2026, 10, 8), minutes: at(10, 15));
      expectTask('завтра в половине восьмого вечера кино',
          title: 'Кино', date: DateTime(2026, 10, 8), minutes: at(19, 30));
      expectTask('в субботу в полдень обед с родителями',
          title: 'Обед с родителями',
          date: DateTime(2026, 10, 10),
          minutes: at(12));
      expectTask('завтра в семь вечера ужин',
          title: 'Ужин', date: DateTime(2026, 10, 8), minutes: at(19));
    });

    test('час без части суток выбирается по смыслу', () {
      expectTask('в 2 ночи посмотреть матч',
          title: 'Посмотреть матч',
          date: DateTime(2026, 10, 8),
          minutes: at(2));
      expectTask('в 10 принять таблетку',
          title: 'Принять таблетку',
          date: DateTime(2026, 10, 7),
          minutes: at(22));
      expectTask('завтра в 10 сдать кровь',
          title: 'Сдать кровь', date: DateTime(2026, 10, 8), minutes: at(10));
      expectTask('сегодня вечером в 8 позвонить',
          title: 'Позвонить', date: DateTime(2026, 10, 7), minutes: at(20));
    });

    test('через минуты и часть суток без дня', () {
      expectTask('через полчаса снять бельё',
          title: 'Снять бельё',
          date: DateTime(2026, 10, 7),
          minutes: at(14, 30));
      expectTask('через 15 минут выйти',
          title: 'Выйти', date: DateTime(2026, 10, 7), minutes: at(14, 15));
      expectTask('утром купить хлеб',
          title: 'Купить хлеб', date: DateTime(2026, 10, 8), minutes: at(9));
      expectTask('вечером позвонить маме',
          title: 'Позвонить маме',
          date: DateTime(2026, 10, 7),
          minutes: at(19));
    });

    test('весь день', () {
      final task = one('завтра весь день дежурство');
      expect(task.title, 'Дежурство');
      expect(task.allDay, isTrue);
      expect(task.need, isNull);
    });
  });

  group('название', () {
    test('без служебных слов', () {
      expectTask('мне завтра надо заплатить за счётчики',
          title: 'Заплатить за счётчики', date: DateTime(2026, 10, 8));
      expectTask('напомни мне завтра в 9 купить корм коту',
          title: 'Купить корм коту',
          date: DateTime(2026, 10, 8),
          minutes: at(9));
      expectTask('пожалуйста в пятницу забрать документы',
          title: 'Забрать документы', date: DateTime(2026, 10, 9));
    });

    test('«завтрак» — не дата', () {
      final task = one('приготовить завтрак');
      expect(task.date, isNull);
      expect(task.title, 'Приготовить завтрак');
    });

    test('только дата — название из фразы, не уверен', () {
      final result = parser.parse('завтра в 10', now);
      expect(result.confident, isFalse);
      expect(result.task.title, 'Завтра в 10');
    });
  });

  group('повторы', () {
    test('каждый день и по будням', () {
      final pills = one('каждый день в 9 утра пить таблетки');
      expect(pills.title, 'Пить таблетки');
      expect(pills.repeat?.kind, PhraseRepeatKind.daily);
      expect(pills.date, DateTime(2026, 10, 8), reason: '9 утра сегодня прошло');
      expect(one('ежедневно в 8 вечера гулять с собакой').date,
          DateTime(2026, 10, 7));
      expect(one('каждое утро делать зарядку').minutes, at(9));
      expect(one('по будням в 7 вставать на работу').repeat?.kind,
          PhraseRepeatKind.weekdays);
    });

    test('дни недели', () {
      final trash = one('каждый понедельник выносить мусор');
      expect(trash.repeat?.weekdays, {1});
      expect(trash.date, DateTime(2026, 10, 12));
      expect(one('по вторникам и четвергам в 7 вечера бассейн').repeat?.weekdays,
          {2, 4});
      expect(one('каждую среду в 6 вечера английский').date,
          DateTime(2026, 10, 7));
      expect(one('по выходным ездить на дачу').date, DateTime(2026, 10, 10));
    });

    test('каждый месяц и каждый год', () {
      final rent = one('каждый месяц 10-го платить за квартиру');
      expect(rent.repeat?.kind, PhraseRepeatKind.monthly);
      expect(rent.date, DateTime(2026, 10, 10));
      expect(rent.title, 'Платить за квартиру');
      final meters = one('каждое 5 число передавать показания счётчиков');
      expect(meters.date, DateTime(2026, 11, 5));
      expect(meters.title, 'Передавать показания счётчиков');
      final grandpa = one('каждый год 9 мая поздравить деда');
      expect(grandpa.repeat?.kind, PhraseRepeatKind.yearly);
      expect(grandpa.date, DateTime(2027, 5, 9));
    });

    test('без повтора', () {
      expect(one('в пятницу позвонить маме').repeat, isNull);
      expect(one('в выходные съездить на дачу').repeat, isNull);
    });
  });

  group('несколько дел', () {
    test('у каждой части свой день — два дела', () {
      final tasks =
          parser.parseMany('завтра купить хлеб и в субботу поменять масло', now);
      expect(tasks.map((task) => task.title), ['Купить хлеб', 'Поменять масло']);
      expect(tasks.last.date, DateTime(2026, 10, 10));
    });

    test('часть без дня приклеивается к предыдущей', () {
      final tasks = parser.parseMany('завтра купить хлеб и молоко', now);
      expect(tasks.single.title, 'Купить хлеб и молоко');
    });
  });

  group('ответ на уточнение', () {
    final tomorrow = DateTime(2026, 10, 8);

    test('время', () {
      TaskAnswer answer(String text) =>
          parser.parseAnswer(text, now, forDate: tomorrow);
      expect(answer('в 10 утра').minutes, at(10));
      expect(answer('10').minutes, at(10));
      expect(answer('десять').minutes, at(10));
      expect(answer('семь вечера').minutes, at(19));
      expect(answer('3').minutes, at(15));
      expect(answer('утром').minutes, at(9));
      expect(answer('весь день').allDay, isTrue);
    });

    test('день, без даты, непонятно', () {
      expect(parser.parseAnswer('послезавтра', now).date, DateTime(2026, 10, 9));
      expect(parser.parseAnswer('без даты', now).noDate, isTrue);
      expect(parser.parseAnswer('ну как-нибудь там', now).isEmpty, isTrue);
    });
  });
}
