import '../recurrence/recurrence_dates.dart';
import 'address_phrases.dart';
import 'moment_hits.dart';
import 'phrase_moments.dart';
import 'phrase_scan.dart';
import 'repeat_phrases.dart';
import 'task_title.dart';
import 'russian_words.dart';
import 'time_phrases.dart';

/// Чего не хватает делу, чтобы записать его без вопросов. День и время
/// спрашиваются всегда; длительность, место, что сделать и срочность — для
/// подробной карточки дела (решение владельца 11 октября 2026).
enum TaskNeed { date, time, duration, place, details, urgency }

/// Дело, выделенное из фразы.
class ParsedTask {
  const ParsedTask({
    required this.title,
    this.date,
    this.minutes,
    this.allDay = false,
    this.repeat,
    this.address,
    this.urgent = false,
    this.durationMinutes,
    this.details,
    this.asked = const {},
  });

  final String title;

  /// Куда ехать: «улица Ленина, 5». В название не входит.
  final String? address;

  /// «Срочно», «важно», «обязательно» — дело важнее прочих.
  final bool urgent;

  /// Сколько займёт: на карточке — «12:00–12:30».
  final int? durationMinutes;

  /// Что там сделать или взять с собой.
  final String? details;

  /// О чём уже спросили — ответили или пропустили: второй раз не спрашивать.
  final Set<TaskNeed> asked;

  /// День дела; у повтора — первый его день.
  final DateTime? date;

  /// Время в минутах от полуночи.
  final int? minutes;

  /// Человек сам сказал, что время не важно.
  final bool allDay;
  final PhraseRepeat? repeat;

  TaskNeed? get need => needFor(detailed: false);

  /// Следующий вопрос о деле. [detailed] — подробная карточка: у дела со
  /// временем ещё длительность, место, что сделать и срочность — кроме уже
  /// сказанного и уже спрошенного.
  TaskNeed? needFor({required bool detailed}) {
    if (date == null) return TaskNeed.date;
    if (minutes == null && !allDay) return TaskNeed.time;
    if (!detailed || minutes == null) return null;
    bool open(TaskNeed need) => !asked.contains(need);
    if (durationMinutes == null && open(TaskNeed.duration)) {
      return TaskNeed.duration;
    }
    if (address == null && open(TaskNeed.place)) return TaskNeed.place;
    if (details == null && open(TaskNeed.details)) return TaskNeed.details;
    if (!urgent && open(TaskNeed.urgency)) return TaskNeed.urgency;
    return null;
  }

  static const _unset = Object();

  ParsedTask copyWith({
    Object? date = _unset,
    Object? minutes = _unset,
    bool? allDay,
    String? address,
    bool? urgent,
    int? durationMinutes,
    String? details,
    TaskNeed? asked,
  }) =>
      ParsedTask(
        title: title,
        date: identical(date, _unset) ? this.date : date as DateTime?,
        minutes: identical(minutes, _unset) ? this.minutes : minutes as int?,
        allDay: allDay ?? this.allDay,
        repeat: repeat,
        address: address ?? this.address,
        urgent: urgent ?? this.urgent,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        details: details ?? this.details,
        asked: asked == null ? this.asked : {...this.asked, asked},
      );
}

/// Разобранная фраза-дело.
class TaskPhrase {
  const TaskPhrase(this.task, {required this.confident});

  final ParsedTask task;

  /// Разбор уверен: есть и название, и день, и ничто не спорит друг с другом.
  final bool confident;
}

/// Ответ на уточняющий вопрос: «в 10 утра», «завтра», «весь день».
class TaskAnswer {
  const TaskAnswer({
    this.date,
    this.minutes,
    this.allDay = false,
    this.noDate = false,
  });

  final DateTime? date;
  final int? minutes;
  final bool allDay;

  /// «Без даты» — записать запиской.
  final bool noDate;

  bool get isEmpty => date == null && minutes == null && !allDay && !noDate;
}

/// Разбор русской фразы о деле по правилам: название, день, время, повтор.
class TaskPhraseParser {
  const TaskPhraseParser();

  TaskPhrase parse(String text, DateTime now) {
    final scan = PhraseScan(text);
    final hits = collectMoments(scan, now);
    final today = dateOnly(now);

    var conflict = hits.dates.length + hits.relative.length > 1 ||
        hits.times.length > 1 ||
        hits.vagueDate;
    DateTime? date;
    int? minutes;

    if (hits.relative.isNotEmpty) {
      final at = now.add(hits.relative.first);
      date = dateOnly(at);
      minutes = at.hour * 60 + at.minute;
      if (hits.times.isNotEmpty) conflict = true;
    } else {
      date = hits.dates.isEmpty ? null : hits.dates.first;
      if (hits.times.isNotEmpty) {
        minutes =
            resolveTime(hits.times.first, hits.dayPart, date ?? today, now);
      } else if (hits.dayPart != null) {
        minutes = dayPartMinutes(hits.dayPart!);
      }
      if (date == null && minutes != null) {
        // Время без дня — ближайшее такое время: сегодня или завтра.
        date = _at(today, minutes).isAfter(now)
            ? today
            : DateTime(today.year, today.month, today.day + 1);
      }
    }

    final repeat = hits.repeat;
    if (repeat != null) {
      final base = hits.dates.isEmpty ? today : hits.dates.first;
      var first = firstRepeatDay(repeat, base: base, from: today);
      if (minutes != null && !_at(first, minutes).isAfter(now)) {
        first = firstRepeatDay(
          repeat,
          base: base,
          from: DateTime(first.year, first.month, first.day + 1),
        );
      }
      date = first;
    }

    // Адрес — после дня и времени: «в 10» номером дома не станет.
    final address = takeAddress(scan);
    final urgent = scan.takes(_urgent);
    final title = cleanTaskTitle(scan.remainder());
    return TaskPhrase(
      ParsedTask(
        address: address,
        urgent: urgent,
        durationMinutes: hits.durationMinutes,
        title: title.isEmpty ? capitalizeFirst(text.trim()) : title,
        date: date,
        minutes: minutes,
        allDay: minutes == null && hits.allDay,
        repeat: repeat ?? (date == null ? null : impliedRepeat(title, date)),
      ),
      confident: date != null && title.isNotEmpty && !conflict,
    );
  }

  /// Ответ на вопрос «во сколько?» или «на какой день?» про дело на
  /// [forDate].
  TaskAnswer parseAnswer(String text, DateTime now, {DateTime? forDate}) {
    final scan = PhraseScan(text);
    final hits = collectMoments(scan, now);
    final baseDate =
        hits.dates.isNotEmpty ? hits.dates.first : forDate ?? dateOnly(now);
    var date = hits.dates.isEmpty ? null : hits.dates.first;
    int? minutes;

    if (hits.relative.isNotEmpty) {
      final at = now.add(hits.relative.first);
      date = dateOnly(at);
      minutes = at.hour * 60 + at.minute;
    } else if (hits.times.isNotEmpty) {
      minutes = resolveTime(hits.times.first, hits.dayPart, baseDate, now);
    } else if (hits.dayPart != null) {
      minutes = dayPartMinutes(hits.dayPart!);
    } else {
      final bare = bareTime(scan.work);
      if (bare != null) minutes = resolveTime(bare, null, baseDate, now);
    }

    return TaskAnswer(
      date: date,
      minutes: minutes,
      allDay: minutes == null && hits.allDay,
      noDate: date == null && minutes == null && hits.noDate,
    );
  }

  /// Несколько дел одной фразой: «завтра в 10 врач, в среду в 15
  /// стоматолог и в пятницу забрать посылку».
  ///
  /// Фраза режется по запятым, «и», «а», «потом» и прямо перед новым днём,
  /// если до него уже было дело. Кусок со своим днём или временем или
  /// начатый действием («оплатить», «позвонить») — новое дело; остальное —
  /// продолжение перечисления: «купить хлеб, молоко и сыр» — одно дело. Дело
  /// без своего дня берёт день предыдущего: «завтра врач в 10 и стоматолог
  /// в 3» — оба завтра.
  List<ParsedTask> parseMany(String text, DateTime now) {
    final whole = parse(text, now);
    if (whole.confident) return [whole.task];
    final groups = <String>[];
    for (final (separator, piece) in _pieces(text)) {
      final own = _hasMoment(piece, now) || _startsWithAction(piece);
      if (groups.isEmpty || own) {
        groups.add(piece);
      } else {
        groups[groups.length - 1] = '${groups.last}$separator$piece';
      }
    }
    if (groups.length < 2) return [whole.task];
    final tasks = <ParsedTask>[];
    for (final group in groups) {
      var task = parse(group, now).task;
      final previous = tasks.lastOrNull?.date;
      final ownDay = collectMoments(PhraseScan(group), now).dates.isNotEmpty;
      if (previous != null && !ownDay && task.repeat == null) {
        task = task.copyWith(date: previous);
      }
      tasks.add(task);
    }
    return tasks;
  }

  /// Куски фразы с тем, что их разделяло.
  static List<(String, String)> _pieces(String text) {
    final pieces = <(String, String)>[];
    var from = 0;
    var separator = '';
    for (final cut in _separator.allMatches(text)) {
      pieces.addAll(_beforeNewDay(separator, text.substring(from, cut.start)));
      separator = cut.group(0)!;
      from = cut.end;
    }
    pieces.addAll(_beforeNewDay(separator, text.substring(from)));
    return [
      for (final piece in pieces)
        if (piece.$2.trim().isNotEmpty) piece,
    ];
  }

  /// «Завтра в 10 врач в среду в 15 стоматолог» — новый день после дела
  /// начинает новое дело и без запятой. «В пятницу 13 октября» — один день:
  /// между ними нет дела.
  static List<(String, String)> _beforeNewDay(String separator, String piece) {
    final work = normalizePhrase(piece);
    final days = _dayStart.allMatches(work).toList();
    final result = <(String, String)>[];
    var from = 0;
    var lead = separator;
    for (var i = 1; i < days.length; i++) {
      final between = work.substring(days[i - 1].end, days[i].start);
      if (!_hasTitleWord(between)) continue;
      result.add((lead, piece.substring(from, days[i].start)));
      lead = ' ';
      from = days[i].start;
    }
    result.add((lead, piece.substring(from)));
    return result;
  }

  static bool _hasTitleWord(String text) => text
      .split(RegExp('[^а-яa-z]+'))
      .any((word) => word.length > 1 && !_timeWords.contains(word));

  bool _hasMoment(String piece, DateTime now) {
    final hits = collectMoments(PhraseScan(piece), now);
    return hits.dates.isNotEmpty ||
        hits.times.isNotEmpty ||
        hits.relative.isNotEmpty ||
        hits.dayPart != null;
  }

  static bool _startsWithAction(String piece) =>
      _action.hasMatch(withoutLeadingFillers(normalizePhrase(piece)));

  static DateTime _at(DateTime day, int minutes) =>
      DateTime(day.year, day.month, day.day, minutes ~/ 60, minutes % 60);
}

/// «Срочно», «важно», «обязательно» — пометка важности, а не название.
final _urgent = phrasePattern('$wordStart(?:срочно|важно|очень\\s+важно'
    '|обязательно)$wordEnd');

/// Где фраза делится на дела: запятая, «и», «а», «потом», «затем».
final _separator = RegExp(
    r'\s*[,;]\s*(?:(?:и|а|а\s+также|а\s+потом|потом|затем)\s+)?'
    r'|\s+(?:и|а|а\s+также|а\s+потом|потом|затем|ещё|еще)\s+',
    caseSensitive: false,
    unicode: true);

/// Начало дня во фразе: «завтра», «в среду», «15 октября», «20 числа».
final _dayStart = phrasePattern('$wordStart(?:(?:в|во|на|к)\\s+)?(?:сегодня'
    '|завтра|послезавтра|понедельник|вторник|среду|четверг|пятницу|субботу'
    '|воскресенье|\\d{1,2}\\s+(?:январ|феврал|март|апрел|ма[яй]|июн|июл|август'
    '|сентябр|октябр|ноябр|декабр)[а-я]*|\\d{1,2}(?:-?го)?\\s+числа)$wordEnd');

/// Слова времени между днями — не дело: «завтра в 10 часов утра в среду».
const _timeWords = {
  'в', 'во', 'на', 'к', 'и', 'а', 'часов', 'часа', 'час', 'утра', 'утром',
  'вечера', 'вечером', 'дня', 'днем', 'ночи', 'ночью', 'половине', 'минут',
  'полдень', 'полночь', 'около', 'примерно',
};

/// Дело, начатое действием: «оплатить интернет», «позвонить маме».
final _action = phrasePattern('^[а-я]+(?:ть|ти|ться|тись)$wordEnd');
