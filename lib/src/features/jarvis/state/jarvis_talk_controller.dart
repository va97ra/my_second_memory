import 'dart:async';

import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'jarvis_controller.dart';
import 'jarvis_listener.dart';
import 'jarvis_message.dart';
import 'jarvis_voice.dart';

/// Голосовой разговор: что слышно прямо сейчас.
@immutable
class JarvisTalk {
  const JarvisTalk({
    this.listening = false,
    this.speaking = false,
    this.heard = '',
    this.problem,
  });

  /// Микрофон включён.
  final bool listening;

  /// Джарвис говорит вслух.
  final bool speaking;

  /// Слушает или говорит: разговор идёт.
  bool get busy => listening || speaking;

  /// Что распознано по ходу речи.
  final String heard;

  /// Почему не вышло послушать — словами для человека.
  final String? problem;
}

final jarvisTalkProvider =
    StateNotifierProvider.autoDispose<JarvisTalkController, JarvisTalk>((ref) {
  return JarvisTalkController(
    listener: ref.watch(jarvisListenerProvider),
    voice: ref.watch(jarvisVoiceProvider),
    jarvis: ref.watch(jarvisControllerProvider.notifier),
    conversation: () => ref.read(jarvisControllerProvider),
  );
});

/// Сказанное — Джарвису, его ответ — вслух.
///
/// Договорив, Джарвис слушает дальше: спросил сам («во сколько?») — ждёт
/// ответа, ответил — ещё [conversationWindow] ждёт продолжения без имени.
/// Так разговаривают, а не заполняют форму. Пока микрофон слушает, лист
/// показывает это строкой «Слушаю»; промолчали — строка тихо исчезает, и
/// дальше Джарвис ждёт только имя.
///
/// «Спасибо», «хватит» разговор заканчивают.
class JarvisTalkController extends StateNotifier<JarvisTalk> {
  JarvisTalkController({
    required JarvisListener? listener,
    required JarvisVoice voice,
    required JarvisController jarvis,
    required JarvisConversation Function() conversation,
    this.conversationWindow = const Duration(seconds: 12),
    this.thinkingPause = const Duration(seconds: 3),
  })  : _listener = listener,
        _voice = voice,
        _jarvis = jarvis,
        _conversation = conversation,
        super(const JarvisTalk());

  final JarvisListener? _listener;
  final JarvisVoice _voice;
  final JarvisController _jarvis;
  final JarvisConversation Function() _conversation;

  /// Сколько после ответа ждать продолжения без имени.
  final Duration conversationWindow;

  /// Сколько ответ может думать молча; дольше — «Секунду, сэр».
  final Duration thinkingPause;

  /// Слушать можно только там, где есть распознавание на устройстве.
  bool get canListen => _listener != null;

  /// Слушать просьбу. [continuation] — продолжение разговора после ответа:
  /// ждём дольше, а промолчали — не ошибка.
  Future<void> listen({bool continuation = false}) async {
    final listener = _listener;
    if (listener == null || state.listening) return;
    await _voice.stop();
    state = const JarvisTalk(listening: true);
    final String said;
    try {
      said = await listener.listen(
        onPartial: (text) {
          if (mounted) state = JarvisTalk(listening: true, heard: text);
        },
        patience: continuation ? conversationWindow : null,
      );
    } on JarvisListenerFailure catch (failure) {
      if (mounted) state = JarvisTalk(problem: failure.message);
      return;
    }
    if (!mounted) return;
    if (said.isEmpty) {
      state = continuation
          ? const JarvisTalk()
          : const JarvisTalk(
              problem: 'Не расслышал. Нажмите и скажите ещё раз.');
      return;
    }
    state = const JarvisTalk();
    await _reply(said);
  }

  /// Джарвиса позвали голосом. Только имя — «Слушаю, сэр» и слушать
  /// просьбу; имя с просьбой — сразу ответить на неё.
  Future<void> respond(String command) async {
    if (command.isEmpty) {
      await _say('Слушаю, $jarvisAddress.');
      if (mounted) await listen();
      return;
    }
    await _reply(command);
  }

  /// Человек ответил текстом: прошлая неудача микрофона больше не к месту.
  /// «Не расслышал» под новой репликой выглядел бы ответом на неё.
  void forgetProblem() {
    if (state.problem != null) state = const JarvisTalk();
  }

  /// Дослушать досрочно — то, что уже сказано, уйдёт Джарвису.
  Future<void> stop() async => _listener?.stop();

  Future<void> _reply(String said) async {
    // По номерам, а не по длине списка: старые реплики разговор отбрасывает,
    // и длина у полного списка не растёт.
    final lastId = _conversation().messages.lastOrNull?.id ?? -1;
    // Нейросеть думает дольше обычного — сказать, что думает: тишина в
    // десятки секунд выглядит поломкой (решение владельца 12 октября 2026).
    Future<void>? thinking;
    final pause = Timer(thinkingPause, () {
      if (mounted) thinking = _say('Секунду, $jarvisAddress.');
    });
    await _jarvis.send(said);
    pause.cancel();
    // Ответ ждёт конца этой фразы: голос обрывает начатую.
    await thinking;
    final answer = [
      for (final message in _conversation().messages)
        if (message.id > lastId && message.fromJarvis) message.text,
    ].join(' ');
    if (answer.isEmpty || !mounted) return;
    await _say(answer);
    if (!mounted) return;
    if (_conversation().asking != null) {
      await listen();
    } else if (!WakeWord.endsConversation(said)) {
      await listen(continuation: true);
    }
  }

  /// Говорит вслух — значок Джарвиса это показывает и не исчезает посреди
  /// фразы.
  Future<void> _say(String text) async {
    if (mounted) state = JarvisTalk(speaking: true, problem: state.problem);
    try {
      await _voice.speak(text);
    } finally {
      if (mounted && state.speaking) {
        state = JarvisTalk(problem: state.problem);
      }
    }
  }

  @override
  void dispose() {
    unawaited(_listener?.cancel());
    unawaited(_voice.stop());
    super.dispose();
  }
}
