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
      expect(
          as<AskAgenda>('какие задачи на пятницу').from, DateTime(2026, 10, 9));
      expect(
          as<AskAgenda>('покажи дела на сегодня').from, DateTime(2026, 10, 7));
    });

    test('число месяца — как его говорят', () {
      // «На 12 число» однажды получило «сегодня дел нет».
      for (final phrase in [
        'какие дела на 12 число',
        'что у меня к 12 числу',
        'какие дела на двенадцатое',
        'что у меня на 12-е',
        'дела на двенадцатое число',
      ]) {
        expect(as<AskAgenda>(phrase).from, DateTime(2026, 10, 12),
            reason: phrase);
      }
      // Число уже прошло в этом месяце — значит, следующий.
      expect(
          as<AskAgenda>('какие дела на 3 число').from, DateTime(2026, 11, 3));
      // День назван, но не разобран — не «сегодня».
      expect(parse('какие дела на 40 число'), isNot(isA<AskAgenda>()));
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
      expect(
          as<CreateTasks>('напомни завтра позвонить маме').requested, isTrue);
      expect(as<CreateTasks>('надо заплатить за свет').requested, isTrue);
    });

    test('повтор, которого календарь не умеет, — честный ответ', () {
      expect(as<JarvisSay>('каждый день в 9 пить таблетки').text,
          contains('«каждый день»'));
      expect(
          parse('каждый месяц 10-го платить за квартиру'), isA<CreateTasks>());
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
      final move =
          as<ChangeRecord>('перенеси встречу с юристом на пятницу в 10');
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
      expect(
          as<Calculate>('посчитай двадцать пять умножить на четыре').expression,
          '25*4');
      expect(as<Calculate>('15 процентов от 2000').expression, '2000*15%');
      expect(as<Calculate>('корень из 144').expression, 'sqrt(144)');
      // Считает калькулятор, Джарвис читает его ответ вслух.
      String said(String phrase) => calculationReply(const CalculatorEngine()
          .evaluate(as<Calculate>(phrase).expression)
          .value);
      expect(said('сколько будет 1 разделить на 3'), 'Получается 0,333333.');
      expect(said('сколько будет 2 в степени 10'), 'Получается 1024.');
    });

    test('величины', () {
      final inches = as<ConvertUnits>('сколько сантиметров в 3 дюймах');
      expect(inches.fromUnit, 'inch');
      expect(inches.toUnit, 'cm');
      expect(inches.value, 3);
      // Переводит конвертер, Джарвис читает его ответ вслух.
      String said(String phrase) {
        final asked = as<ConvertUnits>(phrase);
        return unitReply(
            asked,
            UnitConverter.convert(
              category: asked.category,
              fromUnitId: asked.fromUnit,
              toUnitId: asked.toUnit,
              value: asked.value,
            ));
      }

      expect(said('сколько сантиметров в 3 дюймах'),
          '3 дюйма — это 7,62 сантиметра.');
      expect(said('переведи 5 километров в мили'),
          '5 километров — это 3,1069 мили.');
      expect(as<ConvertUnits>('сколько метров в миле').fromUnit, 'mile');
      expect(said('30 градусов цельсия в фаренгейты'),
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
      // Не назвали, на что, — пусто: Джарвис спросит.
      expect(as<AddFinanceEntry>('заплатил 600').category, isEmpty);
      expect(
          as<AddFinanceEntry>('потратил 20 долларов на такси').currency, 'USD');
    });

    test('покупки — расход, даже без «потратил»', () {
      // С телефона владельца, 12 октября 2026: морковь и сигареты ушли в
      // доход — фразы о покупках правила не знали.
      for (final phrase in [
        'покупки морковь и сигареты 500',
        'запиши покупки морковь и сигареты на 500 рублей',
        'добавь покупку морковь и сигареты 500',
        'запиши в финансы морковь и сигареты 500',
      ]) {
        final entry = as<AddFinanceEntry>(phrase);
        expect(entry.kind, FinanceEntryKind.expense, reason: phrase);
        expect((entry.amount, entry.category), ('500', 'Морковь и сигареты'),
            reason: phrase);
      }
      final salary = as<AddFinanceEntry>('запиши в финансы зарплату 50000');
      expect((salary.kind, salary.category),
          (FinanceEntryKind.income, 'Зарплату'));
      expect(as<AddFinanceEntry>('пришла зарплата 45000').category, 'Зарплата');
    });

    test('обращение к Джарвису — не статья расхода', () {
      // «Такси учти» — так статью собирало всё, что осталось от фразы.
      for (final phrase in [
        'я сегодня на такси пятьсот отдал, учти',
        'короче потратил 500 на такси, запомни',
        'отдал 500 на такси, имей в виду',
      ]) {
        expect(as<AddFinanceEntry>(phrase).category, 'Такси', reason: phrase);
      }
    });

    test('вопросы о деньгах', () {
      final spent = as<AskFinance>('сколько я потратил в этом месяце');
      expect(spent.kind, FinanceEntryKind.expense);
      expect(spent.month, DateTime(2026, 10));
      expect(as<AskFinance>('какой доход в сентябре').month, DateTime(2026, 9));
      expect(as<AskFinance>('сколько я потратил в прошлом месяце').month,
          DateTime(2026, 9));
    });
  });

  group('дни и настройки', () {
    test('смены и праздники', () {
      expect(as<AskShift>('я завтра работаю').day, DateTime(2026, 10, 8));
      expect(
          as<AskShift>('у меня в субботу смена').day, DateTime(2026, 10, 10));
      expect(as<AskShift>('когда смена').findNext, isTrue);
      expect(
          as<AskHolidays>('какой сегодня праздник').day, DateTime(2026, 10, 7));
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
      expect(
          as<SwitchSetting>('скрой праздники').setting, JarvisSwitch.holidays);
    });
  });

  group('пересечения', () {
    test('пароли — отказ, но дело про пароль — дело', () {
      expect(as<JarvisSay>('какой у меня пароль от почты').text,
          contains('Пароли'));
      expect(parse('войди в синхронизацию'), isA<JarvisSay>());
      expect(
          parse('напомни завтра сменить пароль от почты'), isA<CreateTasks>());
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
