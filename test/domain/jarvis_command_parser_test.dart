import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

/// Фраза → команда Джарвиса. Каждая страница приложения — хотя бы одной
/// фразой, и отдельно — пересечения, где одна команда легко принимается за
/// другую.
void main() {
  // Среда, 7 октября 2026, 14:00.
  final now = DateTime(2026, 10, 7, 14);
  const parser = JarvisCommandParser();
  JarvisCommand? parse(String text) => parser.parse(text, now);

  T as<T>(String text) {
    final command = parse(text);
    expect(command, isA<T>(), reason: text);
    return command as T;
  }

  group('обращение', () {
    test('имя и вежливые слова в начале не мешают', () {
      expect(as<OpenPlace>('Джарвис, открой календарь').place,
          JarvisPlace.calendar);
      expect(as<OpenPlace>('джералд пожалуйста открой ленту').place,
          JarvisPlace.feed);
    });

    test('короткие реплики — не дела', () {
      expect(as<JarvisSay>('спасибо').text, isIn(SmallTalk.thanks));
      expect(as<JarvisSay>('ладно на завтра').text, isIn(SmallTalk.ok));
      expect(as<JarvisSay>('Джарвис').text, 'Слушаю.');
    });
  });

  group('страницы', () {
    test('по названию', () {
      final expected = {
        'открой календарь': JarvisPlace.calendar,
        'покажи ленту': JarvisPlace.feed,
        'покажи записки': JarvisPlace.notes,
        'открой архив': JarvisPlace.archive,
        'открой аккаунты': JarvisPlace.accounts,
        'калькулятор': JarvisPlace.calculator,
        'открой финансы': JarvisPlace.finance,
        'перейди в конвертер': JarvisPlace.converter,
        'покажи графики смен': JarvisPlace.shifts,
        'открой производственный календарь': JarvisPlace.productionCalendar,
        'открой настройки': JarvisPlace.settings,
        'открой резервные копии': JarvisPlace.backup,
        'открой синхронизацию': JarvisPlace.sync,
        'покажи праздники': JarvisPlace.holidays,
      };
      for (final entry in expected.entries) {
        expect(as<OpenPlace>(entry.key).place, entry.value, reason: entry.key);
      }
    });

    test('день и месяц', () {
      final tomorrow = as<OpenPlace>('открой завтра');
      expect(tomorrow.place, JarvisPlace.day);
      expect(tomorrow.date, DateTime(2026, 10, 8));
      expect(as<OpenPlace>('покажи 15 ноября').date, DateTime(2026, 11, 15));
      expect(as<OpenPlace>('покажи пятницу').date, DateTime(2026, 10, 9));
      final november = as<OpenPlace>('покажи ноябрь');
      expect(november.place, JarvisPlace.calendar);
      expect(november.date, DateTime(2026, 11));
      expect(as<OpenPlace>('открой календарь на март').date, DateTime(2027, 3));
    });

    test('страница с лишними словами — уже не страница', () {
      expect(parse('покажи записки про дачу'), isA<SearchRecords>());
    });
  });

  group('расписание', () {
    test('день', () {
      final tomorrow = as<AskAgenda>('что у меня завтра');
      expect(tomorrow.from, DateTime(2026, 10, 8));
      expect(tomorrow.isOneDay, isTrue);
      expect(tomorrow.label, 'завтра');
      expect(as<AskAgenda>('какие задачи на пятницу').from,
          DateTime(2026, 10, 9));
      expect(as<AskAgenda>('покажи дела на сегодня').from,
          DateTime(2026, 10, 7));
    });

    test('периоды и без даты', () {
      final weekend = as<AskAgenda>('какие дела на выходных');
      expect(weekend.from, DateTime(2026, 10, 10));
      expect(weekend.to, DateTime(2026, 10, 11));
      final next = as<AskAgenda>('мои планы на следующей неделе');
      expect(next.from, DateTime(2026, 10, 12));
      expect(next.to, DateTime(2026, 10, 18));
      expect(parse('что у меня без даты'), isA<AskUndated>());
    });
  });

  group('записи', () {
    test('дело в календарь', () {
      final create = as<CreateTasks>('завтра в 10 врач');
      expect(create.tasks.single.title, 'Врач');
      expect(create.tasks.single.minutes, 600);
      expect(create.transcript, 'завтра в 10 врач');
    });

    test('просьба записать видна отдельно от разговора', () {
      expect(as<CreateTasks>('ты знаешь фильм Soulmate').requested, isFalse);
      expect(as<CreateTasks>('завтра в 10 врач').requested, isFalse);
      expect(as<CreateTasks>('запиши купить молоко').requested, isTrue);
      expect(as<CreateTasks>('напомни завтра позвонить маме').requested, isTrue);
      expect(as<CreateTasks>('надо заплатить за свет').requested, isTrue);
    });

    test('повтор, которого календарь не умеет, — честный ответ', () {
      expect(as<JarvisSay>('каждый день в 9 пить таблетки').text,
          contains('«каждый день»'));
      expect(parse('каждый месяц 10-го платить за квартиру'),
          isA<CreateTasks>());
    });

    test('записка сохраняет регистр', () {
      expect(as<CreateNote>('запиши заметку: код домофона 45К').text,
          'Код домофона 45К');
      // «Запомни, что …» — Джарвису на память (решение владельца 9 октября
      // 2026), а «запомни купить …» — по-прежнему записка.
      expect(as<RememberFact>('запомни, что ключи у Соседа').fact,
          'Ключи у Соседа');
      expect(as<CreateNote>('запомни купить хлеб').text, 'Купить хлеб');
      expect(parse('запомни что завтра врач'), isA<CreateTasks>());
    });

    test('отметить, вернуть, в архив', () {
      final done = as<ChangeRecord>('отметь врача сделанным');
      expect(done.change, RecordChange.complete);
      expect(done.query, 'врача');
      expect(as<ChangeRecord>('я сделал зарядку').query, 'зарядку');
      expect(as<ChangeRecord>('отметь его выполненным').query, '');
      expect(as<ChangeRecord>('удали стрижку').change, RecordChange.archive);
      expect(as<ChangeRecord>('убери покупки в архив').query, 'покупки');
      expect(as<ChangeRecord>('верни отчёт из архива').change,
          RecordChange.restore);
    });

    test('перенести', () {
      final move = as<ChangeRecord>('перенеси встречу с юристом на пятницу в 10');
      expect(move.change, RecordChange.move);
      expect(move.query, 'встречу юристом');
      expect(move.date, DateTime(2026, 10, 9));
      expect(move.minutes, 600);
      expect(as<ChangeRecord>('перенеси его на завтра').query, '');
    });

    test('найти и «когда»', () {
      expect(as<SearchRecords>('найди счётчики').query, 'счетчики');
      expect(as<AskWhen>('когда у меня стоматолог').query, 'стоматолог');
    });

    test('«отмени»', () {
      expect(parse('отмени'), isA<UndoLast>());
      expect(parse('верни как было'), isA<UndoLast>());
    });
  });

  group('инструменты', () {
    test('счёт', () {
      expect(as<Calculate>('сколько будет 25 на 4').expression, '25*4');
      expect(as<Calculate>('посчитай двадцать пять умножить на четыре')
          .expression, '25*4');
      expect(as<Calculate>('15 процентов от 2000').expression, '2000*15%');
      expect(as<Calculate>('корень из 144').expression, 'sqrt(144)');
      expect(calculationReply(as<Calculate>('сколько будет 1 разделить на 3')),
          'Получается 0,333333.');
      expect(calculationReply(as<Calculate>('сколько будет 2 в степени 10')),
          'Получается 1024.');
    });

    test('величины', () {
      final inches = as<ConvertUnits>('сколько сантиметров в 3 дюймах');
      expect(inches.fromUnit, 'inch');
      expect(inches.toUnit, 'cm');
      expect(inches.value, 3);
      expect(unitReply(inches), '3 дюйма — это 7,62 сантиметра.');
      expect(unitReply(as<ConvertUnits>('переведи 5 километров в мили')),
          '5 километров — это 3,1069 мили.');
      expect(as<ConvertUnits>('сколько метров в миле').fromUnit, 'mile');
      expect(
          unitReply(as<ConvertUnits>('30 градусов цельсия в фаренгейты')),
          '30 градусов Цельсия — это 86 градусов Фаренгейта.');
    });

    test('валюты', () {
      final rate = as<ConvertCurrency>('курс доллара');
      expect((rate.from, rate.to, rate.amount), ('USD', 'RUB', 1.0));
      final hundred = as<ConvertCurrency>('сколько 100 долларов в рублях');
      expect((hundred.from, hundred.to, hundred.amount), ('USD', 'RUB', 100.0));
      final back = as<ConvertCurrency>('переведи 5000 рублей в евро');
      expect((back.from, back.to), ('RUB', 'EUR'));
      expect(
        currencyReply(hundred,
            result: 9450.5, ratesDate: DateTime(2026, 10, 7), now: now),
        'По курсу ЦБ на сегодня 100 долларов — это 9450,5 рубля.',
      );
    });

    test('финансы', () {
      final food = as<AddFinanceEntry>('потратил 500 на продукты');
      expect(food.kind, FinanceEntryKind.expense);
      expect(food.amount, '500');
      expect(food.category, 'Продукты');
      expect(food.date, DateTime(2026, 10, 7));
      final bread = as<AddFinanceEntry>('вчера купил хлеб за 80');
      expect((bread.amount, bread.category), ('80', 'Хлеб'));
      expect(bread.date, DateTime(2026, 10, 6));
      final salary = as<AddFinanceEntry>('получил зарплату пятьдесят тысяч');
      expect(salary.kind, FinanceEntryKind.income);
      expect((salary.amount, salary.category), ('50000', 'Зарплату'));
      expect(as<AddFinanceEntry>('заплатил 600').category, 'Прочее');
      expect(as<AddFinanceEntry>('потратил 20 долларов на такси').currency,
          'USD');
    });

    test('вопросы о деньгах', () {
      final spent = as<AskFinance>('сколько я потратил в этом месяце');
      expect(spent.kind, FinanceEntryKind.expense);
      expect(spent.month, DateTime(2026, 10));
      expect(as<AskFinance>('какой доход в сентябре').month,
          DateTime(2026, 9));
      expect(as<AskFinance>('сколько я потратил в прошлом месяце').month,
          DateTime(2026, 9));
    });
  });

  group('дни и настройки', () {
    test('смены и праздники', () {
      expect(as<AskShift>('я завтра работаю').day, DateTime(2026, 10, 8));
      expect(as<AskShift>('у меня в субботу смена').day,
          DateTime(2026, 10, 10));
      expect(as<AskShift>('когда смена').findNext, isTrue);
      expect(as<AskHolidays>('какой сегодня праздник').day,
          DateTime(2026, 10, 7));
      expect(as<AskHolidays>('что за праздник 4 ноября').day,
          DateTime(2026, 11, 4));
    });

    test('темы и переключатели', () {
      expect(as<ChangeTheme>('включи тёмную тему').theme, JarvisTheme.dark);
      expect(as<ChangeTheme>('поставь светлую тему').theme, JarvisTheme.light);
      expect(as<ChangeTheme>('включи космос').theme, JarvisTheme.cosmos);
      final hints = as<SwitchSetting>('выключи подсказки');
      expect((hints.setting, hints.enabled), (JarvisSwitch.hints, false));
      expect(as<SwitchSetting>('включи международные праздники').setting,
          JarvisSwitch.observances);
      expect(as<SwitchSetting>('скрой праздники').setting,
          JarvisSwitch.holidays);
    });
  });

  group('пересечения', () {
    test('пароли — отказ, но дело про пароль — дело', () {
      expect(as<JarvisSay>('какой у меня пароль от почты').text,
          contains('Пароли'));
      expect(parse('войди в синхронизацию'), isA<JarvisSay>());
      expect(parse('напомни завтра сменить пароль от почты'),
          isA<CreateTasks>());
    });

    test('дело со временем — не вопрос о смене', () {
      expect(parse('завтра смена в 8'), isA<CreateTasks>());
      expect(parse('завтра в 5 пришла посылка'), isA<CreateTasks>());
    });

    test('дело с покупкой — не расход', () {
      expect(parse('завтра купить хлеб'), isA<CreateTasks>());
      expect(parse('завтра заплатить за интернет 600'), isA<CreateTasks>());
    });

    test('вопрос без дня — нейросети, а не в календарь', () {
      expect(as<AskBrain>('Джарвис, почему небо голубое?').text,
          'почему небо голубое');
      expect(parse('что такое ипотека'), isA<AskBrain>());
      expect(as<JarvisSay>('как дела').text, isIn(SmallTalk.howAreYou));
    });
  });
}
