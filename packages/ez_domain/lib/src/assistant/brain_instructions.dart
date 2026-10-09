import '../memory/memory_item.dart';
import 'russian_numbers.dart';
import 'russian_words.dart';
import 'spoken_moments.dart';

/// Что нейросеть Джарвиса знает о себе и что может вызвать.
///
/// Рук у нейросети одна — [JarvisBrainFunctions.runCommand]: она переводит
/// просьбу в короткую команду по-русски, а исполняют её те же правила, что и
/// без нейросети. Так всё, что Джарвис умеет, описано в одном месте, а
/// нейросеть добавляет понимание свободной речи и ответы на любые вопросы.
abstract final class JarvisBrainFunctions {
  static const runCommand = 'run_command';
  static const listDays = 'list_days';
  static const findRecords = 'find_records';
  static const weather = 'get_weather';
  static const wikiLookup = 'wiki_lookup';
  static const news = 'get_news';

  static const specs = <Map<String, Object?>>[
    {
      'name': runCommand,
      'description': 'Выполнить действие в Ежедневнике или узнать справку: '
          'записать дело или записку, перенести, отметить, убрать в архив, '
          'открыть страницу, записать расход или доход, сменить тему, курс '
          'валют, счёт, перевод величин, смены, праздники, будильники '
          'Ежедневника. И телефон: фонарик, будильник и таймер в «Часах», '
          'позвонить или написать контакту, открыть приложение. Возвращает, '
          'что сделано.',
      'parameters': {
        'type': 'object',
        'properties': {
          'phrase': {
            'type': 'string',
            'description': 'Короткая команда по-русски, как сказал бы человек: '
                '«завтра в 10 врач», «перенеси врача на пятницу в 12», '
                '«отметь стоматолога сделанным», «открой финансы», «расход '
                '500 на такси», «курс доллара».',
          },
        },
        'required': ['phrase'],
      },
    },
    {
      'name': listDays,
      'description': 'Дни с from по to включительно: записи календаря, смены '
          'по графикам владельца, праздники, выходные. Нужна для любого '
          'вопроса о делах, планах, работе и свободном времени.',
      'parameters': {
        'type': 'object',
        'properties': {
          'from': {'type': 'string', 'description': 'Первый день, YYYY-MM-DD'},
          'to': {'type': 'string', 'description': 'Последний день, YYYY-MM-DD'},
        },
        'required': ['from', 'to'],
      },
    },
    {
      'name': findRecords,
      'description': 'Найти записи и записки по словам.',
      'parameters': {
        'type': 'object',
        'properties': {
          'query': {'type': 'string', 'description': 'Слова для поиска'},
        },
        'required': ['query'],
      },
    },
    {
      'name': weather,
      'description': 'Погода из интернета (MET Norway): на день и сейчас.',
      'parameters': {
        'type': 'object',
        'properties': {
          'place': {
            'type': 'string',
            'description': 'Город. Не назван — тот, что владелец называл '
                'раньше.',
          },
          'date': {
            'type': 'string',
            'description': 'День, YYYY-MM-DD. Не указан — сегодня.',
          },
        },
      },
    },
    {
      'name': wikiLookup,
      'description': 'Справка из русской Википедии: люди, фильмы, книги, '
          'места, понятия, события.',
      'parameters': {
        'type': 'object',
        'properties': {
          'query': {'type': 'string', 'description': 'Что найти'},
        },
        'required': ['query'],
      },
    },
    {
      'name': news,
      'description': 'Свежие заголовки новостей (ТАСС, РИА, Лента.ру).',
      'parameters': {
        'type': 'object',
        'properties': {
          'topic': {
            'type': 'string',
            'description': 'Тема, если спросили про что-то определённое',
          },
        },
      },
    },
  ];
}

/// Инструкция для нейросети на этот момент: кто она, какое сегодня число и
/// ближайшие дни — без календаря в голове «в пятницу» не превратить в дату.
String jarvisBrainInstructions(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final monday = DateTime(today.year, today.month, today.day - today.weekday + 1);
  final sunday = DateTime(monday.year, monday.month, monday.day + 6);
  final nextMonday = DateTime(monday.year, monday.month, monday.day + 7);
  final nextSunday = DateTime(monday.year, monday.month, monday.day + 13);
  // День недели нейросеть сама высчитывает с ошибками («четверг, 6
  // октября»), поэтому каждый день назван готовым: число, день недели,
  // месяц — от понедельника этой недели и на две недели вперёд.
  final days = StringBuffer();
  for (var day = monday;
      !day.isAfter(nextSunday);
      day = DateTime(day.year, day.month, day.day + 1)) {
    final offset = day.difference(today).inDays;
    final label = switch (offset) {
      0 => ' (сегодня)',
      1 => ' (завтра)',
      2 => ' (послезавтра)',
      < 0 => ' (прошёл)',
      _ => '',
    };
    days.writeln('- ${_isoDate(day)} — ${_dayName(day)}$label');
  }
  final time = '${now.hour.toString().padLeft(2, '0')}:'
      '${now.minute.toString().padLeft(2, '0')}';
  return '''
Ты — Джарвис, личный помощник в приложении «Ежедневник»: календарь, записи, записки, финансы, графики смен, настройки.
Отвечай по-русски и коротко — одно-три предложения, без списков, эмодзи и разметки: ответ прочитают вслух.

Сейчас: ${_dayName(today)} ${today.year} года, $time.
Эта неделя — с понедельника ${_date(monday)} по воскресенье ${_date(sunday)}; следующая — с понедельника ${_date(nextMonday)} по воскресенье ${_date(nextSunday)}.
Дни:
$days
Дни недели и числа бери только из этого списка, сам их не высчитывай.

Записи владельца хранятся в приложении, сам ты их не помнишь.
1. Любое действие в приложении делай через run_command, передав короткую команду по-русски. Одно действие — один вызов. Не говори, что сделал, пока не вызвал функцию; перескажи своими словами её результат.
Записывай дело, только если владелец просит записать или напомнить либо диктует дело с днём или временем («завтра в 10 врач»). Если он просто что-то рассказал или спросил — ответь, ничего не записывая. Не понял, чего он хочет, — спроси коротко: «Что вы хотите, сэр?».
2. На любой вопрос о делах, планах, работе и свободном времени сначала вызови list_days за нужные дни или find_records по словам — без этого не отвечай. У владельца работа по графикам смен: день со сменой — рабочий, даже если это суббота. Свободный день — без смен и без записей. Не выдумывай записей, которых нет в ответе функции.
3. Курс валют, счёт, перевод величин, смены, праздники и будильники — тоже run_command: «курс доллара», «сколько будет 25 на 4», «я завтра работаю», «какие у меня будильники». Телефон — тоже: «включи фонарик», «разбуди меня в 6:30», «таймер на 10 минут», «позвони маме», «напиши Васе в ватсап, что опоздаю», «открой камеру». Звонок и сообщение не уходят сами — владелец нажимает «Вызов» или «Отправить».
4. Из интернета: погода — get_weather, справка о людях, фильмах, книгах, местах и понятиях — wiki_lookup, новости — get_news. Не выдумывай погоду и новости. Коротко назови источник («по данным MET Norway»). Если функция вернула ошибку — скажи об этом или сделай, как она советует; справка недоступна — ответь по памяти и предупреди, что это по памяти.
5. Пароли, логины и PIN-код не трогай и не спрашивай: это владелец делает сам.
6. На обычные вопросы, советы, объяснения и просьбы написать текст отвечай сам, коротко и по делу.
7. Если просьба непонятна, задай один короткий уточняющий вопрос.
Стиль: учтиво и сдержанно, как английский дворецкий. Обращайся «сэр» — естественно, не в каждой фразе.''';
}

/// День так, как его видит нейросеть: записи, смены по графикам и
/// праздники вместе — «свободный день» иначе не понять.
Map<String, Object?> dayForBrain(
  DateTime day, {
  required List<MemoryItem> records,
  required List<String> shifts,
  required List<String> holidays,
  required bool hasShiftSchedules,
}) =>
    {
      'date': _isoDate(day),
      'day': _dayName(day),
      if (day.weekday >= DateTime.saturday) 'weekend': true,
      if (hasShiftSchedules)
        'shifts': shifts.isEmpty ? 'выходной по графикам' : shifts,
      if (holidays.isNotEmpty) 'holidays': holidays,
      'records': [for (final item in records) recordForBrain(item)],
    };

/// Запись так, как её видит нейросеть: день — словами, чтобы ей не
/// пришлось высчитывать день недели самой.
Map<String, Object?> recordForBrain(MemoryItem item) => {
      'title': item.title,
      if (!item.isUndated) 'date': _isoDate(item.memoryDate),
      if (!item.isUndated) 'day': _dayName(item.memoryDate),
      if (item.timeMinutes != null) 'time': spokenClock(item.timeMinutes!),
      if (item.isDone) 'done': true,
      if (item.isUndated) 'note': true,
    };

/// Ответ нейросети без разметки: его читают вслух.
String cleanBrainReply(String raw) {
  var text = raw
      .replaceAll(RegExp(r'<[^>]{1,40}>'), ' ')
      .replaceAll(RegExp(r'[*_#`>|]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (text.length > 700) text = '${text.substring(0, 697).trimRight()}…';
  return capitalizeFirst(text);
}

/// Дата из ответа нейросети: `YYYY-MM-DD`.
DateTime? parseBrainDate(Object? value) {
  final match =
      RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch('${value ?? ''}'.trim());
  if (match == null) return null;
  final date = DateTime(int.parse(match.group(1)!), int.parse(match.group(2)!),
      int.parse(match.group(3)!));
  return date.month == int.parse(match.group(2)!) ? date : null;
}

/// «четверг, 8 октября».
String _dayName(DateTime day) => '${_weekdays[day.weekday - 1]}, ${_date(day)}';

/// «8 октября».
String _date(DateTime day) => '${day.day} ${monthsGenitive[day.month - 1]}';

String _isoDate(DateTime day) => '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

const _weekdays = [
  'понедельник',
  'вторник',
  'среда',
  'четверг',
  'пятница',
  'суббота',
  'воскресенье',
];
