import '../metro/metro_guide.dart';
import 'agenda_phrases.dart';
import 'calculation_phrases.dart';
import 'currency_phrases.dart';
import 'day_question_phrases.dart';
import 'fact_phrases.dart';
import 'finance_phrases.dart';
import 'history_phrases.dart';
import 'jarvis_command.dart';
import 'jarvis_phrase.dart';
import 'moment_hits.dart';
import 'phone_phrases.dart';
import 'place_phrases.dart';
import 'record_phrases.dart';
import 'russian_words.dart';
import 'setting_phrases.dart';
import 'small_talk.dart';
import 'task_phrase.dart';
import 'unit_phrases.dart';

/// Мозг на правилах: фраза → команда. Без сети и без нейросети, мгновенно.
///
/// Порядок проверок — от самых узких к самым широким: отказ и «отмени»
/// раньше всего, дело — последним, потому что делом можно счесть почти любую
/// фразу. Каждая проверка либо уверенно узнаёт свою команду, либо молчит.
class JarvisCommandParser {
  const JarvisCommandParser();

  /// Команда или null, если фраза пустая.
  JarvisCommand? parse(String raw, DateTime now) {
    final phrase = JarvisPhrase(raw);
    if (phrase.isEmpty) {
      // Позвали по имени и замолчали — ждём просьбу.
      return raw.trim().isEmpty ? null : const JarvisSay('Слушаю.');
    }
    final work = phrase.work;
    final talk = SmallTalk.reply(phrase.text, now);
    return refusalCommand(work, now) ??
        undoCommand(work) ??
        (talk == null ? null : JarvisSay(talk)) ??
        settingCommand(work) ??
        factCommand(phrase, now) ??
        phoneCommand(phrase, now) ??
        _metroCommand(phrase.text) ??
        historyCommand(work, now) ??
        agendaCommand(work, now) ??
        dayQuestionCommand(work, now) ??
        financeCommand(work, now) ??
        calculationCommand(work) ??
        currencyCommand(work) ??
        unitCommand(work) ??
        recordChangeCommand(work, now) ??
        searchCommand(work) ??
        whenCommand(work) ??
        noteCommand(phrase, now) ??
        placeCommand(work, now) ??
        phoneAppCommand(work, now) ??
        _taskCommand(phrase, now);
  }

  /// Вопрос о дороге на метро; станции узнаёт схема метро.
  JarvisCommand? _metroCommand(String text) {
    final asked = MetroGuide.moscow.question(text);
    return asked == null ? null : AskMetroRoute(from: asked.from, to: asked.to);
  }

  JarvisCommand _taskCommand(JarvisPhrase phrase, DateTime now) {
    const parser = TaskPhraseParser();
    final whole = parser.parse(phrase.text, now);
    // Вопрос без дня — не дело: «почему небо голубое» записывать незачем.
    if (phrase.isQuestion && whole.task.date == null) {
      return AskBrain(phrase.text);
    }
    final tasks = parser.parseMany(phrase.text, now);
    for (final task in tasks) {
      final repeat = task.repeat;
      if (repeat != null && !_calendarRepeats(repeat.kind)) {
        return JarvisSay(unsupportedRepeatReply(repeat.kind));
      }
    }
    return CreateTasks(
      tasks,
      transcript: phrase.raw,
      requested: _recordRequest.hasMatch(phrase.work),
      confident: !phrase.isQuestion &&
          tasks.every((task) =>
              _words(task.title) <= _dictationWords &&
              !_commandInside.hasMatch(normalizePhrase(task.title))),
    );
  }

  /// Просьба посреди названия значит, что фраза разобрана неверно: «сходить
  /// к врачу, запиши меня куда-нибудь» — не название дела.
  static final _commandInside = phrasePattern('$wordStart(?:запиши|запишите'
      '|напомни|напомните|добавь|поставь|создай|перенеси|отметь)$wordEnd');

  /// Слова, которыми просят записать.
  static final _recordRequest = phrasePattern('$wordStart(?:запиши|запишите'
      '|записать|запомни|напомни|напомните|напомнить|добавь|добавьте|поставь'
      '|создай|запланируй|внеси|заведи|надо|нужно|не\\s+забыть|не\\s+забудь'
      '|задач[аиу])$wordEnd');

  /// Диктовка дела — короткая: «завтра в 10 врач», «купить молоко». Длиннее
  /// восьми слов — уже рассказ, и понимать его лучше нейросетью.
  static const _dictationWords = 8;

  static int _words(String text) =>
      text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
}

/// Календарь повторяет записи раз в месяц и раз в год — и только.
bool _calendarRepeats(PhraseRepeatKind kind) =>
    kind == PhraseRepeatKind.monthly || kind == PhraseRepeatKind.yearly;

/// Честный ответ на повтор, которого календарь не умеет.
String unsupportedRepeatReply(PhraseRepeatKind kind) {
  final what = switch (kind) {
    PhraseRepeatKind.daily => '«каждый день»',
    PhraseRepeatKind.weekdays => '«по будням»',
    _ => '«по дням недели»',
  };
  return 'Повторять $what календарь пока не умеет — только раз в месяц или '
      'раз в год. Скажите день, и я запишу один раз.';
}
