import 'jarvis_command.dart';
import 'jarvis_phrase.dart';
import 'phrase_moments.dart';
import 'phrase_scan.dart';
import 'russian_words.dart';
import 'task_phrase.dart';

/// Действия над записью: «отметь врача сделанным», «я сделал зарядку»,
/// «перенеси встречу на пятницу в 10», «убери покупки в архив», «удали
/// стрижку», «верни отчёт из архива».
///
/// Запрос — слова, по которым запись ищется; пустой запрос («отметь его»)
/// означает запись, о которой только что шла речь.
JarvisCommand? recordChangeCommand(String work, DateTime now) {
  for (final (pattern, change) in _changes) {
    final match = pattern.firstMatch(work);
    if (match != null) {
      return ChangeRecord(change, query: _query(match.namedGroup('q') ?? ''));
    }
  }
  final move = _move.firstMatch(work);
  if (move == null) return null;
  final scan = PhraseScan(move.namedGroup('rest')!);
  final hits = collectMoments(scan, now);
  if (hits.dates.isEmpty && hits.times.isEmpty && hits.relative.isEmpty) {
    return null;
  }
  final answer =
      const TaskPhraseParser().parseAnswer(move.namedGroup('rest')!, now);
  return ChangeRecord(
    RecordChange.move,
    query: _query(scan.work),
    date: answer.date,
    minutes: answer.minutes,
  );
}

/// «найди врача», «поищи записи про счётчики», «покажи заметки о даче».
JarvisCommand? searchCommand(String work) {
  final match = _search.firstMatch(work);
  if (match == null) return null;
  final query = _query(match.namedGroup('q')!);
  return query.isEmpty ? null : SearchRecords(query);
}

/// «когда у меня врач», «когда стрижка».
JarvisCommand? whenCommand(String work) {
  final match = _when.firstMatch(work);
  if (match == null) return null;
  final query = _query(match.namedGroup('q')!);
  return query.isEmpty ? null : AskWhen(query);
}

/// «запиши заметку: код домофона 45», «заметка купить батарейки»,
/// «запомни, что ключи у соседа». Текст сохраняет регистр сказанного.
JarvisCommand? noteCommand(JarvisPhrase phrase, DateTime now) {
  final match =
      _note.firstMatch(phrase.work) ?? _remember.firstMatch(phrase.work);
  if (match == null) return null;
  // «Запомни, что мама любит розы» — это Джарвису на память, а не записка;
  // записка — когда просят сделать дело: «запомни купить хлеб».
  if (identical(match.pattern, _remember) &&
      !_doing.hasMatch(match.namedGroup('t')!)) {
    return null;
  }
  // Текст записки — до конца фразы, поэтому его начало считается от конца
  // совпадения; рабочая копия и исходный текст одной длины.
  final start = match.end - match.namedGroup('t')!.length;
  final text = compactPhrase(phrase.text.substring(start));
  if (text.isEmpty) return null;
  // «запомни, что завтра врач» — это дело на завтра, а не записка.
  if (identical(match.pattern, _remember) &&
      const TaskPhraseParser().parse(text, now).task.date != null) {
    return null;
  }
  return CreateNote(capitalizeFirst(text));
}

/// «отмени», «верни как было».
JarvisCommand? undoCommand(String work) =>
    _undo.hasMatch(work) ? const UndoLast() : null;

/// Пароли, входы и PIN — не дело Джарвиса. Напоминание с днём («завтра
/// сменить пароль») — обычное дело: в нём нет самого пароля.
JarvisCommand? refusalCommand(String work, DateTime now) {
  if (!_secret.hasMatch(work) && !_signIn.hasMatch(work)) return null;
  if (const TaskPhraseParser().parse(work, now).task.date != null) return null;
  return const JarvisSay(
      'Пароли, входы и PIN-код я не трогаю — это только ваше. Могу открыть '
      'аккаунты, дальше вы сами.');
}

/// Слова запроса без местоимений и служебных слов.
String _query(String raw) {
  final words = compactPhrase(raw.replaceAll(_queryNoise, ' '));
  return _pronoun.hasMatch(words) ? '' : words;
}

const _done = '(?:как\\s+)?(?:сделанн[а-я]*|выполненн[а-я]*|готов[а-я]*'
    '|завершенн[а-я]*)';

final _changes = <(RegExp, RecordChange)>[
  (
    phrasePattern('^(?:отметь|пометь|отмечай)\\s+$_done(?:\\s+(?<q>.+))?\$'),
    RecordChange.complete
  ),
  (
    phrasePattern('^(?:отметь|пометь|отмечай)\\s+(?<q>.+?)\\s+$_done\$'),
    RecordChange.complete
  ),
  (
    phrasePattern('^(?:я\\s+)?(?:сделал|сделала|выполнил|выполнила|закончил'
        '|закончила|завершил|завершила)(?:\\s+(?<q>.+))?\$'),
    RecordChange.complete
  ),
  (phrasePattern('^(?:готово|сделано|выполнено)\$'), RecordChange.complete),
  (
    phrasePattern('^(?:сними\\s+отметку\\s+(?:с|со)|верни\\s+в\\s+работу)'
        '\\s+(?<q>.+)\$'),
    RecordChange.reopen
  ),
  (phrasePattern('^верни\\s+(?<q>.+?)\\s+в\\s+работу\$'), RecordChange.reopen),
  (
    phrasePattern(
        '^(?:верни|восстанови|достань)\\s+(?<q>.+?)\\s+из\\s+архива\$'),
    RecordChange.restore
  ),
  (
    phrasePattern('^(?:убери|отправь|перенеси|положи)\\s+(?<q>.+?)'
        '\\s+в\\s+архив\$'),
    RecordChange.archive
  ),
  (
    phrasePattern('^(?:архивируй|заархивируй|удали|сотри|убери)\\s+(?<q>.+)\$'),
    RecordChange.archive
  ),
];

final _move = phrasePattern('^(?:перенеси|передвинь|перемести|сдвинь|подвинь'
    '|отложи|поменяй\\s+время)\\s+(?<rest>.+)\$');

final _search = phrasePattern('^(?:найди|поищи|ищи|отыщи|покажи'
    '\\s+(?:записи|запись|записки|заметки)\\s+(?:про|о|об|со?\\s+словом))'
    '\\s+(?<q>.+)\$');

final _when = phrasePattern('^когда\\s+(?:у\\s+меня\\s+)?(?:будет\\s+)?'
    '(?<q>.+)\$');

final _note = phrasePattern('^(?:запиши|напиши|сделай|создай|добавь|новая'
    '|новую)?'
    '\\s*(?:записку|заметку|записка|заметка)[\\s:,.\\-—]+(?<t>.+)\$');

final _remember = phrasePattern('^запомни[\\s,:]+(?:что[\\s,]+)?(?<t>.+)\$');

/// Дело начинается с действия: «купить хлеб», «позвонить маме».
final _doing = phrasePattern('^[а-я]+(?:ть|ти|ться|тись)$wordEnd');

final _undo = phrasePattern('^(?:отмени|отмена|отменить|верни\\s+как\\s+было'
    '|верни\\s+обратно|откати|не\\s+надо\\s+было)(?:\\s+(?:это|последнее'
    '|все|пожалуйста|назад))*\$');

final _secret = phrasePattern('$wordStart(?:парол[а-я]*|логин[а-я]*'
    '|пин[\\s-]?код[а-я]*|пинкод[а-я]*)$wordEnd');

final _signIn = phrasePattern('^(?:войди|зайди\\s+в\\s+аккаунт|выйди\\s+из'
    '|авторизуйся|залогинься|разблокируй|сними\\s+блокировку)$wordEnd');

final _queryNoise = phrasePattern('$wordStart(?:мне|пожалуйста|запись|записи'
    '|дело|задачу|задача|на|про|о|об|в|из|с|со|как|все|всё|моя|мою|мое|мой'
    '|у\\s+меня|у)$wordEnd');

final _pronoun = phrasePattern('^(?:его|ее|это|эту|этот|ее|их|последн[а-я]*'
    '|только\\s+что[а-я\\s]*)?\$');
