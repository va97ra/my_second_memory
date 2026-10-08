import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'jarvis_controller.dart';
import 'jarvis_listener.dart';
import 'jarvis_message.dart';
import 'jarvis_voice.dart';

/// Голосовой разговор: что слышно прямо сейчас.
@immutable
class JarvisTalk {
  const JarvisTalk({this.listening = false, this.heard = '', this.problem});

  /// Микрофон включён.
  final bool listening;

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
/// Если Джарвис в ответ сам спросил («во сколько?»), микрофон включается
/// снова, как только он договорит: отвечать голосом, не нажимая кнопку, —
/// так разговаривают, а не заполняют форму.
class JarvisTalkController extends StateNotifier<JarvisTalk> {
  JarvisTalkController({
    required JarvisListener? listener,
    required JarvisVoice voice,
    required JarvisController jarvis,
    required JarvisConversation Function() conversation,
  })  : _listener = listener,
        _voice = voice,
        _jarvis = jarvis,
        _conversation = conversation,
        super(const JarvisTalk());

  final JarvisListener? _listener;
  final JarvisVoice _voice;
  final JarvisController _jarvis;
  final JarvisConversation Function() _conversation;

  /// Слушать можно только там, где есть распознавание на устройстве.
  bool get canListen => _listener != null;

  Future<void> listen() async {
    final listener = _listener;
    if (listener == null || state.listening) return;
    await _voice.stop();
    state = const JarvisTalk(listening: true);
    final String said;
    try {
      said = await listener.listen(onPartial: (text) {
        if (mounted) state = JarvisTalk(listening: true, heard: text);
      });
    } on JarvisListenerFailure catch (failure) {
      if (mounted) state = JarvisTalk(problem: failure.message);
      return;
    }
    if (!mounted) return;
    if (said.isEmpty) {
      state = const JarvisTalk(problem: 'Не расслышал. Нажмите и скажите ещё раз.');
      return;
    }
    state = const JarvisTalk();
    await _reply(said);
  }

  /// Дослушать досрочно — то, что уже сказано, уйдёт Джарвису.
  Future<void> stop() async => _listener?.stop();

  Future<void> _reply(String said) async {
    // По номерам, а не по длине списка: старые реплики разговор отбрасывает,
    // и длина у полного списка не растёт.
    final lastId = _conversation().messages.lastOrNull?.id ?? -1;
    await _jarvis.send(said);
    final answer = [
      for (final message in _conversation().messages)
        if (message.id > lastId && message.fromJarvis) message.text,
    ].join(' ');
    if (answer.isEmpty || !mounted) return;
    await _voice.speak(answer);
    if (mounted && _conversation().asking != null) await listen();
  }

  @override
  void dispose() {
    unawaited(_listener?.cancel());
    unawaited(_voice.stop());
    super.dispose();
  }
}
