import 'dart:async';

import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/state/bool_setting_controller.dart';
import 'jarvis_brain.dart';
import 'jarvis_brain_providers.dart';
import 'jarvis_executor.dart';
import 'jarvis_message.dart';
import 'jarvis_outcome.dart';
import 'jarvis_task_questions.dart';

final jarvisControllerProvider =
    StateNotifierProvider<JarvisController, JarvisConversation>((ref) {
  return JarvisController(
    ref.watch(jarvisExecutorProvider),
    brain: () async {
      await ref.read(gigaChatKeyProvider.notifier).ready;
      return ref.read(jarvisBrainProvider);
    },
    detailed: () => ref.read(jarvisDetailedCardsProvider),
  );
});

/// «Подробная карточка дела»: о деле со временем Джарвис спрашивает ещё
/// длительность, место, что сделать и срочность. Включено, пока владелец
/// не выключит (решение 11 октября 2026).
final jarvisDetailedCardsProvider = boolSettingProvider(
  storageKey: 'jarvis_detailed_cards_v1',
  initial: true,
);

/// Разговор с Джарвисом: реплики, уточнения по новым делам и отмена.
///
/// Разговор живёт, пока открыто приложение, и в хранилище не пишется:
/// записи, которые он заводит, — обычные записи календаря, а не история
/// чата.
class JarvisController extends StateNotifier<JarvisConversation> {
  JarvisController(
    this._executor, {
    Future<JarvisBrain?> Function()? brain,
    bool Function()? detailed,
    DateTime Function()? clock,
  })  : _brain = brain ?? _noBrain,
        _questions = JarvisTaskQuestions(detailed: detailed ?? _plain),
        _clock = clock ?? DateTime.now,
        super(const JarvisConversation());

  final JarvisExecutor _executor;

  /// Нейросеть, если ключ GigaChat сохранён. Спрашивается в момент вопроса:
  /// ключ могли ввести, пока разговор уже шёл, а сразу после запуска его
  /// ещё читают с диска — тогда ответа дожидаются.
  final Future<JarvisBrain?> Function() _brain;
  static Future<JarvisBrain?> _noBrain() async => null;
  static bool _plain() => false;

  /// Уточнения по новым делам — день, время и подробности карточки.
  final JarvisTaskQuestions _questions;
  final DateTime Function() _clock;
  final _persona = const ButlerPersona(jarvisAddress);
  final _replies = StreamController<String>.broadcast();

  /// Сколько реплик держать на экране: разговор — не архив.
  static const _keptMessages = 100;

  var _nextId = 0;
  MemoryItem? _mentioned;

  /// Что сделать с ответом на вопрос, который Джарвис задал последним.
  Future<JarvisOutcome?> Function(String said, DateTime now)? _followUp;

  Future<void> Function()? _undo;

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
      _add(JarvisAuthor.jarvis, JarvisReplies.failed);
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

  /// Очистить разговор. Записи, которые Джарвис завёл, остаются: стирается
  /// только сам разговор — реплики, начатые уточнения, «отменить» и память
  /// нейросети о сказанном.
  Future<void> clear() async {
    if (state.busy) return;
    _questions.clear();
    _mentioned = null;
    _undo = null;
    _followUp = null;
    state = const JarvisConversation();
    (await _brain())?.forget();
  }

  /// Джарвис сделал дело сам, без просьбы, — записал расход по уведомлению
  /// банка. В разговоре это видно так же, как сказанное, с «Отменить».
  Future<void> act(JarvisCommand command) async {
    final now = _clock();
    _apply(await _executor.run(command, mentioned: _mentioned, now: now));
  }

  /// Кнопка «Показать» под ответом.
  void show(OpenPlace target) => _open(target);

  /// Экран открыл страницу, о которой просили.
  void navigationHandled() => state = state.copyWith(clearNavigation: true);

  Future<void> _handle(String said, DateTime now) async {
    if (_questions.asking) {
      final handled = await _clarify(said, now);
      if (handled) return;
    }
    // Джарвис спросил сам («На что потратили?», «Записать, сэр?») —
    // короткая фраза, которая не просьба, это ответ.
    final followUp = _followUp;
    _followUp = null;
    if (followUp != null && answersJarvis(said, now)) {
      final answered = await followUp(said, now);
      if (answered != null) {
        _apply(answered);
        return;
      }
    }
    final command = const JarvisCommandParser().parse(said, now);
    switch (command) {
      case null:
        return;
      case UndoLast():
        await _runUndo();
      case AskBrain(:final text):
        await _askBrain(text, now);
      case CreateTasks(:final tasks, :final transcript) && final create:
        // Не просили записать или разобрано неуверенно — понимать нейросетью,
        // если она подключена: «ты знаешь фильм…» — разговор, а не дело.
        final brain =
            create.requested && create.confident ? null : await _brain();
        if (brain != null) {
          await _askBrainWith(brain, transcript, now);
          return;
        }
        // Без нейросети фразу без просьбы и без дня не записываем наугад.
        if (!create.requested && tasks.every((task) => task.date == null)) {
          _jarvis(JarvisReplies.whatToDo);
          return;
        }
        _questions.add(tasks, transcript: transcript);
        await _continue(now);
      default:
        _apply(await _executor.run(command, mentioned: _mentioned, now: now));
    }
  }

  /// Вопрос, на который правила не отвечают, — нейросети. Нет её или нет
  /// связи — Джарвис говорит об этом прямо, а не делает вид, что понял.
  Future<void> _askBrain(String text, DateTime now) async {
    final brain = await _brain();
    if (brain == null) {
      // Без нейросети Джарвис отвечает хотя бы тем, что ему велели помнить.
      _apply(_executor.recall(text) ??
          const JarvisOutcome(JarvisReplies.needsBrain));
      return;
    }
    await _askBrainWith(brain, text, now);
  }

  Future<void> _askBrainWith(
          JarvisBrain brain, String text, DateTime now) async =>
      _apply(await brain.answer(text, mentioned: _mentioned, now: now));

  /// Ответ на вопрос о деле. true — фраза была ответом и обработана.
  Future<bool> _clarify(String said, DateTime now) async {
    final answered = _questions.answer(said, now);
    switch (answered.result) {
      case TaskQuestionResult.dropped
          when !_questions.asking && !_questions.hasReady:
        _jarvis(JarvisReplies.dropped(answered.task));
        state = state.copyWith(clearAsking: true);
        return true;
      case TaskQuestionResult.dropped:
      case TaskQuestionResult.answered:
        await _continue(now);
        return true;
      case TaskQuestionResult.newRequest:
        await _continue(now);
        return false;
    }
  }

  /// Спросить про следующее дело или записать всё готовое.
  Future<void> _continue(DateTime now) async {
    final next = _questions.next;
    if (next != null) {
      _jarvis(JarvisReplies.question(next.task, next.need));
      state = state.copyWith(asking: next.task, askingNeed: next.need);
      return;
    }
    state = state.copyWith(clearAsking: true);
    final tasks = _questions.takeReady();
    if (tasks.isEmpty) return;
    _apply(await _executor.create(tasks,
        transcript: _questions.transcript, now: now));
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
    _followUp = outcome.followUp;
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
