import '../recurrence/recurrence_dates.dart';
import 'moment_hits.dart';
import 'phrase_moments.dart';
import 'phrase_scan.dart';
import 'repeat_phrases.dart';
import 'russian_words.dart';
import 'time_phrases.dart';

/// Чего не хватает делу, чтобы записать его без вопросов.
enum TaskNeed { date, time }

/// Дело, выделенное из фразы.
class ParsedTask {
  const ParsedTask({
    required this.title,
    this.date,
    this.minutes,
    this.allDay = false,
    this.repeat,
  });

  final String title;

  /// День дела; у повтора — первый его день.
  final DateTime? date;

  /// Время в минутах от полуночи.
  final int? minutes;

  /// Человек сам сказал, что время не важно.
  final bool allDay;
  final PhraseRepeat? repeat;

  TaskNeed? get need {
    if (date == null) return TaskNeed.date;
    if (minutes == null && !allDay) return TaskNeed.time;
    return null;
  }

  static const _unset = Object();

  ParsedTask copyWith({
    Object? date = _unset,
    Object? minutes = _unset,
    bool? allDay,
  }) =>
      ParsedTask(
        title: title,
        date: identical(date, _unset) ? this.date : date as DateTime?,
        minutes: identical(minutes, _unset) ? this.minutes : minutes as int?,
        allDay: allDay ?? this.allDay,
        repeat: repeat,
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

    final title = cleanTaskTitle(scan.remainder());
    return TaskPhrase(
      ParsedTask(
        title: title.isEmpty ? capitalizeFirst(text.trim()) : title,
        date: date,
        minutes: minutes,
        allDay: minutes == null && hits.allDay,
        repeat: repeat,
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

  /// Одна фраза — одно или несколько дел: «завтра купить хлеб и в субботу
  /// поменять масло» — два дела. Делим, только если у двух частей свой день;
  /// часть без дня приклеивается к предыдущей («купить хлеб и молоко»).
  List<ParsedTask> parseMany(String text, DateTime now) {
    final whole = parse(text, now);
    if (whole.confident) return [whole.task];
    final parts =
        text.split(_joiner).where((part) => part.trim().isNotEmpty).toList();
    if (parts.length < 2) return [whole.task];
    final merged = <String>[];
    for (final part in parts) {
      final hasDate = parse(part, now).task.date != null;
      if (merged.isEmpty || hasDate) {
        merged.add(part);
      } else {
        merged[merged.length - 1] = '${merged.last} и $part';
      }
    }
    if (merged.length < 2) return [whole.task];
    return [for (final part in merged) parse(part, now).task];
  }

  static DateTime _at(DateTime day, int minutes) =>
      DateTime(day.year, day.month, day.day, minutes ~/ 60, minutes % 60);
}

/// Название дела из того, что осталось от фразы после дня и времени: без
/// «напомни», «надо», висящих предлогов и «часов» от «утром часов в 10».
String cleanTaskTitle(String text) {
  var title = compactPhrase(text);
  title = title.replaceAll(_please, ' ');
  String previous;
  do {
    previous = title;
    title = title.replaceFirst(RegExp(r'^[\s,.;:!?—–-]+'), '');
    title = title.replaceFirst(_leadingFillers, '');
    title = title.replaceFirst(RegExp(r'[\s,.;:!?—–-]+$'), '');
    title = title.replaceFirst(_danglingPreposition, '');
    title = title.replaceFirst(_danglingApproximation, '');
  } while (title != previous);
  title = title
      .replaceAll(RegExp(r'\s+([,.;:!?])'), r'$1')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return capitalizeFirst(title);
}

const _fillers =
    'напомните|напомни|напомнить|запиши|запишите|запомни|мне|нам|надо\\s+бы'
    '|надо|нужно|необходимо|не\\s+забыть|не\\s+забудь|что|чтобы|и|а|ну|так'
    '|вот|слушай|слушайте|короче|значит|кстати|в\\s+общем|пожалуй|давай|бы'
    '|где-то|где\\s+то|примерно|джарвис|сэр';

final _please = RegExp('$wordStart(?:пожалуйста)$wordEnd',
    caseSensitive: false, unicode: true);

final _leadingFillers =
    RegExp('^(?:$_fillers)$wordEnd', caseSensitive: false, unicode: true);

final _danglingPreposition = RegExp('$wordStart(?:в|во|на|к|до|и|а|с)\$',
    caseSensitive: false, unicode: true);

final _danglingApproximation = RegExp(
    '$wordStart(?:часов|часиков|часа|примерно|около|где-то|где\\s+то)\$',
    caseSensitive: false,
    unicode: true);

final _joiner =
    RegExp(r'\s+(?:и|а\s+также|а\s+потом|потом|ещё|еще)\s+', unicode: true);
