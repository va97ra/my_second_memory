import '../memory/memory_edit.dart';
import '../recurrence/recurrence_series.dart';
import 'jarvis_command.dart';
import 'jarvis_phrase.dart';
import 'phone_phrases.dart' show durationSeconds;
import 'phrase_moments.dart';
import 'phrase_scan.dart';
import 'record_phrases.dart' show recordQuery;
import 'russian_words.dart';

/// Правка готовой записи голосом: «перенеси врача на час позже», «напомни
/// о враче за час», «убери напоминание у врача», «поставь будильник на
/// врача», «переименуй врача в стоматолога», «допиши к врачу: взять полис»,
/// «врач займёт два часа», «сделай врача срочным», «сделай врача
/// ежемесячным», «перестань повторять врача».
///
/// Каждая фраза меняет одно, и только названное, — так же, как правит запись
/// нейросеть ([RecordEdit]). Запись ищется по словам; «его», «это» — та, о
/// которой только что говорили.
JarvisCommand? recordEditCommand(JarvisPhrase phrase, DateTime now) {
  final work = phrase.work;
  // Текст до конца фразы — как сказан, с заглавными: рабочая копия и
  // исходный текст одной длины, поэтому его начало считается от конца.
  String tail(RegExpMatch match, String group) {
    final length = match.namedGroup(group)!.length;
    return compactPhrase(phrase.text.substring(match.end - length, match.end));
  }

  EditRecord edit(RegExpMatch match, RecordEdit change) =>
      EditRecord(query: _queryOf(match), edit: change);

  int? minutesOf(RegExpMatch match) {
    final seconds = durationSeconds(match.namedGroup('span')!);
    return seconds == null ? null : seconds ~/ 60;
  }

  if (_shift.firstMatch(work) case final match?
      when !_clockTime.hasMatch(match.namedGroup('span')!)) {
    if (minutesOf(match) case final minutes?) {
      final earlier = _earlier.hasMatch(match.namedGroup('dir') ?? '');
      return edit(
          match, RecordEdit(shiftMinutes: earlier ? -minutes : minutes));
    }
  }
  if (_remindBefore.firstMatch(work) case final match?) {
    if (minutesOf(match) case final minutes?) {
      return edit(match, RecordEdit(reminderBefore: minutes));
    }
  }
  if (_removeReminder.firstMatch(work) case final match?) {
    return edit(match, const RecordEdit(removeReminder: true));
  }
  if (_removeAlarm.firstMatch(work) case final match?) {
    return edit(match, const RecordEdit(alarm: false));
  }
  if (_alarmOn.firstMatch(work) case final match?) {
    // «Будильник на 7», «будильник на завтра» — будильник телефона, а не
    // записи: там названо время.
    final target = match.namedGroup('q')!;
    final hits = collectMoments(PhraseScan(target), now);
    final timed = hits.dates.isNotEmpty ||
        hits.times.isNotEmpty ||
        hits.relative.isNotEmpty ||
        RegExp(r'\d').hasMatch(target);
    if (!timed) return edit(match, const RecordEdit(alarm: true));
  }
  if (_rename.firstMatch(work) case final match?) {
    final title = tail(match, 't');
    if (title.isNotEmpty) {
      return edit(match, RecordEdit(title: capitalizeFirst(title)));
    }
  }
  if (_append.firstMatch(work) case final match?) {
    final rest = match.namedGroup('rest')!;
    final said = tail(match, 'rest');
    final split = _appendSplit.firstMatch(rest);
    if (split != null) {
      final text = said.substring(split.end).trim();
      if (text.isNotEmpty) {
        return EditRecord(
          query: recordQuery(
              rest.substring(0, split.start).replaceAll(_noteWord, ' ')),
          edit: RecordEdit(addText: text),
        );
      }
    }
    final whole = compactPhrase(said.replaceFirst(_leadingNoteWord, ''));
    if (whole.isNotEmpty) return EditRecord(appendTo: whole);
  }
  if (_lasts.firstMatch(work) case final match?) {
    if (minutesOf(match) case final minutes?) {
      return edit(match, RecordEdit(durationMinutes: minutes));
    }
  }
  if (_notUrgent.firstMatch(work) case final match?) {
    return edit(match, const RecordEdit(urgent: false));
  }
  if (_urgent.firstMatch(work) case final match?) {
    return edit(match, const RecordEdit(urgent: true));
  }
  if (_stopRepeat.firstMatch(work) case final match?) {
    return EditRecord(query: _queryOf(match), stopRepeat: true);
  }
  if (_repeat.firstMatch(work) case final match?) {
    final how = match.namedGroup('how') ?? match.namedGroup('how2')!;
    return EditRecord(
      query: _queryOf(match),
      repeat: _yearly.hasMatch(how)
          ? RecurrenceFrequency.yearly
          : RecurrenceFrequency.monthly,
    );
  }
  return null;
}

/// Запрос из группы `q`, а у шаблонов с двумя порядками слов — из `q2`.
String _queryOf(RegExpMatch match) {
  final raw = match.namedGroup('q') ??
      (match.groupNames.contains('q2') ? match.namedGroup('q2') : null);
  return recordQuery(raw ?? '');
}

/// «Час», «полчаса», «полтора часа», «15 минут», «два дня».
const _span = '(?<span>(?:[^\\s]+\\s+){0,2}(?:час[а-я]*|минут[а-я]*|мин'
    '|день|дня|дней|сутки|суток)|полчаса)';

final _shift = phrasePattern('^(?:перенеси|передвинь|перемести|сдвинь'
    '|подвинь|отложи)(?:\\s+(?<q>.+?))?\\s+на\\s+$_span(?:\\s+(?<dir>позже'
    '|попозже|вперед|раньше|пораньше|назад))?\$');
final _earlier = phrasePattern('^(?:раньше|пораньше|назад)\$');

/// «На 2 часа дня», «на 7 утра» — время суток, а не сдвиг.
final _clockTime = phrasePattern('$wordStart(?:утра|вечера|ночи)$wordEnd'
    '|час[а-я]*\\s+дня$wordEnd');

final _remindBefore = phrasePattern('^(?:напомни(?:\\s+мне)?|поставь'
    '\\s+напоминание)\\s+(?:о|об|обо|про|для|к|на)\\s+(?<q>.+?)\\s+за'
    '\\s+$_span\$');

final _removeReminder = phrasePattern('^(?:(?:убери|сними|удали|отключи'
    '|выключи|отмени)\\s+напоминани[а-я]*(?:\\s+(?<q>.+))?'
    '|не\\s+напоминай(?:\\s+мне)?\\s+(?:о|об|обо|про)\\s+(?<q2>.+))\$');

final _removeAlarm = phrasePattern('^(?:убери|сними|удали|отключи|выключи'
    '|отмени)\\s+будильник\\s+(?:у|с|со|для|на|к)\\s+(?<q>.+)\$');

final _alarmOn = phrasePattern('^(?:поставь|поставить|включи|сделай'
    '|заведи)\\s+будильник\\s+(?:на|для|к|у)\\s+(?<q>.+)\$');

final _rename = phrasePattern('^(?:переименуй|переназови)\\s+(?<q>.+?)'
    '\\s+(?:в|на)\\s+(?<t>.+)\$');

final _append = phrasePattern('^(?:(?:допиши|дополни|припиши)\\s+(?:к|ко|в'
    '|во)|добавь\\s+(?:к|ко))\\s+(?<rest>.+)\$');

/// «к врачу: взять полис», «в записку про ремонт — обои», «к врачу, что
/// нужен полис».
final _appendSplit = phrasePattern('\\s*(?:[:—–]|\\s-\\s|,?\\s+что\\s)\\s*');

final _noteWord =
    phrasePattern('$wordStart(?:записк[а-я]*|заметк[а-я]*)$wordEnd');
final _leadingNoteWord = phrasePattern('^(?:записк[а-я]*|заметк[а-я]*)'
    '(?:\\s+(?:про|о|об))?\\s+');

final _lasts = phrasePattern('^(?<q>.+?)\\s+(?:займет|продлится|длится'
    '|будет\\s+длиться)\\s+$_span\$');

final _urgent = phrasePattern('^(?:сделай|отметь|пометь)\\s+(?<q>.+?)'
    '\\s+(?:срочн|важн)[а-я]*\$');
final _notUrgent = phrasePattern('^(?:(?:сделай|отметь|пометь)\\s+(?<q>.+?)'
    '\\s+(?:не\\s*срочн|не\\s*важн|обычн)[а-я]*'
    '|сними\\s+(?:срочность|важность)\\s+(?:с|со|у)\\s+(?<q2>.+))\$');

/// «Сделай врача ежемесячным» и «пусть врач повторяется каждый месяц».
/// «Сделай уборку каждый месяц» сюда не входит: это новое дело с повтором.
final _repeat = phrasePattern('^(?:(?:сделай|пусть)\\s+(?<q>.+?)\\s+(?:будет'
    '\\s+)?(?<how>ежемесячн[а-я]*|ежегодн[а-я]*)|(?:пусть|повторяй)\\s+'
    '(?<q2>.+?)\\s+(?:будет\\s+|повторяется\\s+)?(?<how2>каждый\\s+месяц'
    '|каждый\\s+год|раз\\s+в\\s+месяц|раз\\s+в\\s+год))\$');
final _yearly = phrasePattern('$wordStart(?:ежегодн[а-я]*|год)$wordEnd');

final _stopRepeat = phrasePattern('^(?:(?:перестань|прекрати|хватит)'
    '\\s+повторять|не\\s+повторяй|(?:убери|сними|отключи|отмени)'
    '\\s+повтор[а-я]*\\s+(?:у|с|со|для))\\s+(?<q>.+)\$');
