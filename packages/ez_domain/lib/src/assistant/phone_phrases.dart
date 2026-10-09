import '../language/russian_plural.dart';
import 'jarvis_command.dart';
import 'jarvis_phrase.dart';
import 'russian_numbers.dart';
import 'russian_words.dart';
import 'spoken_moments.dart';
import 'task_phrase.dart';

/// Команды телефону без нейросети: фонарик, будильник, таймер, звонок и
/// сообщение. Дело на потом — «позвонить маме завтра в 10» — не команда:
/// его записывают, а не набирают.
///
/// Перенесено из MemoryVoice, где проверено на телефоне владельца.
JarvisCommand? phoneCommand(JarvisPhrase phrase, DateTime now) {
  final work = phrase.work;
  if (_torchOff.hasMatch(work)) return const PhoneTorch(on: false);
  if (_torchOn.hasMatch(work)) return const PhoneTorch(on: true);

  final alarm = _alarm.firstMatch(work);
  if (alarm != null) {
    final minutes = alarmMinutes(
        alarm.namedGroup('when') ?? alarm.namedGroup('wake') ?? '', now);
    return minutes == null ? const JarvisSay(PhoneReplies.alarmNeedsTime)
        : PhoneAlarm(minutes);
  }

  final timer = _timer.firstMatch(work);
  if (timer != null) {
    final seconds =
        durationSeconds(timer.namedGroup('length') ?? timer.namedGroup('count') ?? '');
    return seconds == null ? const JarvisSay(PhoneReplies.timerNeedsLength)
        : PhoneTimer(seconds);
  }

  // «Напиши поздравление маме» — просьба сочинить текст, а не отправить:
  // сообщение узнаётся по приложению, «что» или слову «сообщение».
  final message = _message.firstMatch(work);
  if (message != null &&
      (message.namedGroup('app') != null ||
          message.namedGroup('that') != null ||
          message.namedGroup('noun') != null)) {
    // Текст стоит в конце фразы; берётся с исходными заглавными буквами —
    // разбор не меняет длину фразы.
    final said = message.namedGroup('text')!;
    final text = phrase.text.substring(phrase.text.length - said.length);
    return PhoneMessage(
      message.namedGroup('who')!,
      text,
      app: switch (message.namedGroup('app')) {
        final app? when app.startsWith('в') || app.startsWith('w') =>
          PhoneMessenger.whatsapp,
        final app? when app.startsWith('т') || app.startsWith('t') =>
          PhoneMessenger.telegram,
        _ => PhoneMessenger.sms,
      },
    );
  }

  final call = _call.firstMatch(work);
  if (call != null && !_scheduled(work, now)) {
    return PhoneCall(call.namedGroup('who')!);
  }
  return null;
}

/// «Открой камеру», «запусти телеграм» — приложение телефона. Проверяется
/// после страниц Ежедневника: «открой календарь» — его собственная страница.
JarvisCommand? phoneAppCommand(String work, DateTime now) {
  final open = _open.firstMatch(work);
  if (open == null || _scheduled(work, now)) return null;
  return PhoneOpenApp(open.namedGroup('app')!);
}

/// Время будильника в минутах от полуночи: «6:30», «в 7», «на 8 утра».
/// Без «вечера» и без часов за полдень — утро: будильник ведь.
int? alarmMinutes(String when, DateTime now) {
  final said = when.trim().replaceFirst(_on, 'в ');
  final minutes = const TaskPhraseParser().parseAnswer(said, now).minutes;
  if (minutes == null) return null;
  final hour = RegExp(r'\d+').firstMatch(said);
  final said24 = hour != null && int.parse(hour[0]!) >= 13;
  if (minutes >= 13 * 60 && !said24 && !_evening.hasMatch(said)) {
    return minutes - 12 * 60;
  }
  return minutes;
}

/// Длина таймера в секундах: «10 минут», «полтора часа», «1 час 20 минут»,
/// «45 секунд», «минуту». null — длины не названо.
int? durationSeconds(String text) {
  final work = normalizePhrase(text);
  var total = 0;
  if (_halfHour.hasMatch(work)) total += 30 * 60;
  for (final match in _unit.allMatches(work)) {
    final raw = match.namedGroup('n');
    final unit = match.namedGroup('u')!;
    final seconds = unit.startsWith('ч')
        ? 3600
        : unit.startsWith('м')
            ? 60
            : 1;
    if (raw == 'полтора' || raw == 'полторы') {
      total += seconds * 3 ~/ 2;
      continue;
    }
    // «На минуту», «одну минуту» — одна; «пару минут» — две.
    final count = raw == null
        ? 1
        : int.tryParse(raw) ??
            numberFromWords(raw) ??
            (raw.startsWith('пар') ? 2 : 1);
    total += count * seconds;
  }
  return total > 0 ? total : null;
}

/// «45 секунд», «10 минут», «1 час 20 минут».
String spokenSeconds(int seconds) {
  if (seconds < 60) {
    return '$seconds ${russianPlural(seconds, 'секунду', 'секунды', 'секунд')}';
  }
  final rest = seconds % 60;
  final minutes = spokenDuration(seconds ~/ 60);
  return rest == 0
      ? minutes
      : '$minutes $rest ${russianPlural(rest, 'секунду', 'секунды', 'секунд')}';
}

/// Что Джарвис отвечает на команды телефону.
abstract final class PhoneReplies {
  static const alarmNeedsTime =
      'Скажите вместе со временем: «Будильник на 7 утра».';
  static const timerNeedsLength =
      'Скажите, на сколько: «Таймер на 10 минут».';
  static const notHere = 'На этом устройстве я так не умею.';
  static const contactsDenied = 'Без доступа к контактам я не найду номер. '
      'Разрешите его или назовите номер цифрами.';

  static String torch({required bool on, required bool done}) => !done
      ? 'Фонарика на этом телефоне я не нашёл.'
      : on
          ? 'Фонарик включил.'
          : 'Фонарик выключил.';

  static String alarm(int minutes, {required bool done}) => done
      ? 'Будильник в «Часах» поставил на ${spokenClock(minutes)}.'
      : 'Не нашёл приложение «Часы».';

  static String timer(int seconds, {required bool done}) => done
      ? 'Таймер на ${spokenSeconds(seconds)} запустил.'
      : 'Не нашёл приложение «Часы».';

  static String notFound(String who) => 'Не нашёл «$who» в контактах.';

  static String dialing(String name) => 'Набираю: $name. Нажмите «Вызов».';

  static String written(String name, PhoneMessenger app) => switch (app) {
        PhoneMessenger.telegram =>
          'Открыл Telegram: выберите чат с $name и нажмите «Отправить».',
        PhoneMessenger.whatsapp ||
        PhoneMessenger.sms =>
          'Написал для $name. Проверьте и нажмите «Отправить».',
      };

  static String noMessenger(PhoneMessenger app) => switch (app) {
        PhoneMessenger.telegram => 'Telegram на телефоне не нашёл.',
        PhoneMessenger.whatsapp => 'WhatsApp на телефоне не нашёл.',
        PhoneMessenger.sms => 'Не получилось открыть сообщения.',
      };

  static String opened(String label) => 'Открываю «$label».';

  static String noApp(String name) => 'Не нашёл приложение «$name».';
}

/// Есть день или время — это дело на потом, а не команда сейчас.
bool _scheduled(String work, DateTime now) {
  final task = const TaskPhraseParser().parse(work, now).task;
  return task.date != null || task.minutes != null;
}

final _torchOn = phrasePattern(
    '$wordStart(?:включи|зажги|вруби|включить)\\s+фонарик$wordEnd');
final _torchOff = phrasePattern(
    '$wordStart(?:выключи|погаси|выруби|выключить)\\s+фонарик$wordEnd');

final _alarm = phrasePattern(
    '^(?:(?:поставь|заведи|установи)\\s+)?будильник'
    '(?:\\s+(?<when>.+))?\$|^разбуди(?:\\s+меня)?\\s+(?<wake>.+)\$');

final _on = phrasePattern('^на\\s+');
final _evening = phrasePattern('$wordStart(?:вечера|вечером|дня|днем|ночи)$wordEnd');

final _timer = phrasePattern(
    '^(?:(?:поставь|заведи|включи|запусти)\\s+)?таймер'
    '(?:\\s+(?:на\\s+)?(?<length>.+))?\$|^засеки\\s+(?<count>.+)\$');

final _halfHour = phrasePattern('$wordStartполчаса$wordEnd');
final _unit = phrasePattern(
    '(?:$wordStart(?<n>\\d+|полтора|полторы|[а-я]+(?:\\s+[а-я]+)?)\\s+)?'
    '$wordStart(?<u>час|часа|часов|минуту|минуты|минут|мин|секунду|секунды'
    '|секунд|сек)$wordEnd');

final _call = phrasePattern(
    '^(?:позвони|набери|звякни|вызови)\\s+(?<who>.+)\$');

final _message = phrasePattern(
    '^(?:напиши|отправь|скинь)\\s+(?<noun>сообщение\\s+)?'
    '(?<who>[а-яa-z0-9+]+),?\\s+'
    '(?:в\\s+(?<app>ватсап|вотсап|whatsapp|телеграм|телеграмм|telegram'
    '|телегу|смс|sms)\\s*,?\\s+)?(?<that>что\\s+)?(?<text>.+)\$');

final _open = phrasePattern('^(?:открой|запусти)\\s+(?<app>.+)\$');

/// Какой контакт назвали: «маме» — «Мама», «Васе» — «Вася Петров».
///
/// Имя в речи склоняется, а в контактах записано как есть, поэтому слова
/// сравниваются началом: общее начало не короче трёх букв и расходится не
/// больше чем на два последних. Лучший — с самым длинным общим началом, при
/// равенстве — с самым коротким именем. null — никто не подходит.
int? bestContact(String spoken, List<String> names) {
  final said = [
    for (final word in normalizePhrase(spoken).split(RegExp('[^а-яa-z0-9]+')))
      if (word.length > 1) word,
  ];
  if (said.isEmpty) return null;
  int? best;
  var bestScore = 0;
  for (final (index, name) in names.indexed) {
    final words = normalizePhrase(name).split(RegExp('[^а-яa-z0-9]+'));
    var score = 0;
    for (final word in said) {
      var top = 0;
      for (final candidate in words) {
        final common = _commonStart(word, candidate);
        final shorter =
            word.length < candidate.length ? word.length : candidate.length;
        if (common >= 3 && common >= shorter - 2 && common > top) top = common;
      }
      if (top == 0) {
        score = 0;
        break;
      }
      score += top;
    }
    final better = score > bestScore ||
        (score == bestScore &&
            score > 0 &&
            best != null &&
            name.length < names[best].length);
    if (better) {
      best = index;
      bestScore = score;
    }
  }
  return best;
}

int _commonStart(String left, String right) {
  var count = 0;
  while (count < left.length &&
      count < right.length &&
      left[count] == right[count]) {
    count++;
  }
  return count;
}
