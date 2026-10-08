import 'dart:async';

import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ez_data/ez_data.dart' show GigaChatException;

import 'jarvis_brain.dart';
import 'jarvis_brain_providers.dart';
import 'jarvis_executor.dart';
import 'jarvis_message.dart';
import 'jarvis_outcome.dart';

export 'jarvis_brain_providers.dart' show jarvisAddress;

final jarvisControllerProvider =
    StateNotifierProvider<JarvisController, JarvisConversation>((ref) {
  return JarvisController(
    ref.watch(jarvisExecutorProvider),
    brain: () => ref.read(jarvisBrainProvider),
  );
});

/// Разговор с Джарвисом: реплики, уточнения по новым делам и отмена.
///
/// Разговор живёт, пока открыто приложение, и в хранилище не пишется:
/// записи, которые он заводит, — обычные записи календаря, а не история
/// чата.
class JarvisController extends StateNotifier<JarvisConversation> {
  JarvisController(
    this._executor, {
    JarvisBrain? Function()? brain,
    DateTime Function()? clock,
  })  : _brain = brain ?? _noBrain,
        _clock = clock ?? DateTime.now,
        super(const JarvisConversation());

  final JarvisExecutor _executor;

  /// Нейросеть, если ключ GigaChat сохранён. Спрашивается в момент вопроса:
  /// ключ могли ввести, пока разговор уже шёл.
  final JarvisBrain? Function() _brain;
  static JarvisBrain? _noBrain() => null;
  final DateTime Function() _clock;
  final _persona = const ButlerPersona(jarvisAddress);
  final _replies = StreamController<String>.broadcast();

  /// Сколько реплик держать на экране: разговор — не архив.
  static const _keptMessages = 100;

  var _nextId = 0;
  MemoryItem? _mentioned;
  Future<void> Function()? _undo;

  /// Дела, которым не хватает дня или времени; спрашивается первое.
  final _waiting = <ParsedTask>[];

  /// Дела, готовые к записи, пока уточняются остальные.
  final _ready = <ParsedTask>[];
  String _transcript = '';

  /// Каждый ответ Джарвиса — с обращением, как он показан. Для голоса.
  Stream<String> get replies => _replies.stream;

  /// Человек сказал или написал [text].
  Future<void> send(String text) async {
    final said = text.trim();
    if (said.isEmpty || state.busy) return;
    _add(JarvisAuthor.person, said);
    state = state.copyWith(busy: true);
    try {
      await _handle(said, _clock());
    } catch (error, stack) {
      // Человек должен узнать, что просьба не выполнена; сама ошибка уходит
      // дальше, в журнал, а не глохнет здесь.
      _add(JarvisAuthor.jarvis,
          'Не получилось — что-то пошло не так. Попробуйте ещё раз.');
      Error.throwWithStackTrace(error, stack);
    } finally {
      if (mounted) state = state.copyWith(busy: false);
    }
  }

  /// Кнопка «Отменить» под последним действием.
  Future<void> undo() async {
    if (state.busy) return;
    state = state.copyWith(busy: true);
    try {
      await _runUndo();
    } finally {
      if (mounted) state = state.copyWith(busy: false);
    }
  }

  /// Кнопка «Показать» под ответом.
  void show(OpenPlace target) => _open(target);

  /// Экран открыл страницу, о которой просили.
  void navigationHandled() => state = state.copyWith(clearNavigation: true);

  Future<void> _handle(String said, DateTime now) async {
    if (_waiting.isNotEmpty) {
      final handled = await _clarify(said, now);
      if (handled) return;
    }
    final command = const JarvisCommandParser().parse(said, now);
    switch (command) {
      case null:
        return;
      case UndoLast():
        await _runUndo();
      case AskBrain(:final text):
        await _askBrain(text, now);
      case CreateTasks(confident: false, :final transcript)
          when _brain() != null:
        await _askBrain(transcript, now);
      case CreateTasks(:final tasks, :final transcript):
        _transcript = transcript;
        for (final task in tasks) {
          (task.need == null ? _ready : _waiting).add(task);
        }
        await _continue(now);
      default:
        _apply(await _executor.run(command, mentioned: _mentioned, now: now));
    }
  }

  /// Вопрос, на который правила не отвечают, — нейросети. Нет её или нет
  /// связи — Джарвис говорит об этом прямо, а не делает вид, что понял.
  Future<void> _askBrain(String text, DateTime now) async {
    final brain = _brain();
    if (brain == null) {
      _jarvis(JarvisReplies.needsBrain);
      return;
    }
    try {
      _apply(await brain.ask(text, mentioned: _mentioned, now: now));
    } on GigaChatException catch (failure) {
      _jarvis(failure.message);
    }
  }

  /// Ответ на «во сколько?». true — фраза была ответом и обработана.
  Future<bool> _clarify(String said, DateTime now) async {
    final task = _waiting.first;
    switch (readClarification(said, now, forDate: task.date)) {
      case ClarificationCancel():
        _waiting.removeAt(0);
        if (_waiting.isEmpty && _ready.isEmpty) {
          _jarvis(JarvisReplies.dropped(task));
          state = state.copyWith(clearAsking: true);
        } else {
          await _continue(now);
        }
        return true;
      case ClarificationAnswer(:final answer):
        _waiting[0] = _answered(task, answer);
        if (_waiting.first.need == null || answer.noDate) {
          _ready.add(_waiting.removeAt(0));
        }
        await _continue(now);
        return true;
      case ClarificationNewRequest():
        // Заговорили о другом: начатое записывается как есть — без дня
        // запиской, без времени на весь день, — а просьба выполняется.
        for (final waiting in _waiting) {
          _ready.add(waiting.need == TaskNeed.time
              ? waiting.copyWith(allDay: true)
              : waiting.copyWith(date: null));
        }
        _waiting.clear();
        await _continue(now);
        return false;
    }
  }

  ParsedTask _answered(ParsedTask task, TaskAnswer answer) {
    if (answer.noDate) {
      // «Не знаю» на вопрос о времени — день остаётся, время не важно.
      return task.need == TaskNeed.time
          ? task.copyWith(allDay: true)
          : task.copyWith(date: null);
    }
    var result = task;
    if (answer.date != null) result = result.copyWith(date: answer.date);
    if (answer.minutes != null) {
      result = result.copyWith(minutes: answer.minutes, allDay: false);
    }
    if (answer.allDay) result = result.copyWith(minutes: null, allDay: true);
    return result;
  }

  /// Спросить про следующее дело или записать всё готовое.
  Future<void> _continue(DateTime now) async {
    if (_waiting.isNotEmpty) {
      final task = _waiting.first;
      _jarvis(JarvisReplies.question(task));
      state = state.copyWith(asking: task);
      return;
    }
    state = state.copyWith(clearAsking: true);
    if (_ready.isEmpty) return;
    final tasks = [..._ready];
    _ready.clear();
    _apply(await _executor.create(tasks, transcript: _transcript, now: now));
  }

  Future<void> _runUndo() async {
    final undo = _undo;
    if (undo == null) {
      _jarvis(JarvisReplies.nothingToUndo);
      return;
    }
    _undo = null;
    state = state.copyWith(clearUndo: true);
    await undo();
    _jarvis(JarvisReplies.undone);
  }

  void _apply(JarvisOutcome outcome) {
    if (outcome.mentioned != null) _mentioned = outcome.mentioned;
    final id = _jarvis(outcome.say, link: outcome.link);
    if (outcome.undo != null) {
      _undo = outcome.undo;
      state = state.copyWith(undoMessageId: id);
    }
    final open = outcome.open;
    if (open != null) _open(open);
  }

  void _open(OpenPlace target) {
    _executor.prepare(target);
    state = state.copyWith(navigation: JarvisNavigation(target));
  }

  int _jarvis(String text, {OpenPlace? link}) {
    final said = _persona.apply(text);
    final id = _add(JarvisAuthor.jarvis, said, link: link);
    _replies.add(said);
    return id;
  }

  int _add(JarvisAuthor author, String text, {OpenPlace? link}) {
    final id = _nextId++;
    final messages = [
      ...state.messages,
      JarvisMessage(id: id, author: author, text: text, link: link),
    ];
    final start =
        messages.length > _keptMessages ? messages.length - _keptMessages : 0;
    state = state.copyWith(messages: messages.sublist(start));
    return id;
  }

  @override
  void dispose() {
    _replies.close();
    super.dispose();
  }
}
