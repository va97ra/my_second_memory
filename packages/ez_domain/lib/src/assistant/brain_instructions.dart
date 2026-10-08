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
  static const listRecords = 'list_records';
  static const findRecords = 'find_records';

  static const specs = <Map<String, Object?>>[
    {
      'name': runCommand,
      'description': 'Выполнить действие в Ежедневнике или узнать справку: '
          'записать дело или записку, перенести, отметить, убрать в архив, '
          'открыть страницу, записать расход или доход, сменить тему, курс '
          'валют, счёт, перевод величин, смены, праздники. Возвращает, что '
          'сделано.',
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
      'name': listRecords,
      'description': 'Записи календаря за дни с from по to включительно.',
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
  ];
}

/// Инструкция для нейросети на этот момент: кто она, какое сегодня число и
/// ближайшие дни — без календаря в голове «в пятницу» не превратить в дату.
String jarvisBrainInstructions(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final days = StringBuffer();
  for (var i = 0; i < 14; i++) {
    final day = DateTime(today.year, today.month, today.day + i);
    final label = switch (i) {
      0 => 'сегодня, ',
      1 => 'завтра, ',
      2 => 'послезавтра, ',
      _ => '',
    };
    days.writeln('- $label${_weekdays[day.weekday - 1]} ${_isoDate(day)}');
  }
  final time = '${now.hour.toString().padLeft(2, '0')}:'
      '${now.minute.toString().padLeft(2, '0')}';
  return '''
Ты — Джарвис, личный помощник в приложении «Ежедневник»: календарь, записи, записки, финансы, графики смен, настройки.
Отвечай по-русски и коротко — одно-три предложения, без списков, эмодзи и разметки: ответ прочитают вслух.

Сейчас: ${_weekdays[today.weekday - 1]}, ${today.day} ${monthsGenitive[today.month - 1]} ${today.year} года, $time.
Ближайшие дни:
$days
Записи владельца хранятся в приложении, сам ты их не помнишь.
1. Любое действие в приложении делай через run_command, передав короткую команду по-русски. Одно действие — один вызов. Не говори, что сделал, пока не вызвал функцию; перескажи своими словами её результат.
2. Вопросы о делах и планах — list_records за нужные дни или find_records по словам. Не выдумывай записей, которых нет в ответе функции.
3. Курс валют, счёт, перевод величин, смены и праздники — тоже run_command: «курс доллара», «сколько будет 25 на 4», «я завтра работаю».
4. Пароли, логины и PIN-код не трогай и не спрашивай: это владелец делает сам.
5. На обычные вопросы, советы, объяснения и просьбы написать текст отвечай сам, коротко и по делу.
6. Если просьба непонятна, задай один короткий уточняющий вопрос.
Стиль: учтиво и сдержанно, как английский дворецкий. Обращайся «сэр» — естественно, не в каждой фразе.''';
}

/// Запись так, как её видит нейросеть.
Map<String, Object?> recordForBrain(MemoryItem item) => {
      'title': item.title,
      if (!item.isUndated) 'date': _isoDate(item.memoryDate),
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
