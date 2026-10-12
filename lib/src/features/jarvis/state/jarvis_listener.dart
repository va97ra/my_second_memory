import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'jarvis_listener_stub.dart'
    if (dart.library.io) 'jarvis_listener_io.dart';

/// Слух Джарвиса: одна фраза с микрофона в текст.
///
/// Распознаёт на самом устройстве, без сети и без сервисов Google. В вебе
/// такого движка нет — там провайдер отдаёт null, и Джарвис принимает
/// только написанное.
abstract interface class JarvisListener {
  /// Слушает одну фразу до паузы. [onPartial] получает текст по ходу речи.
  /// Возвращает итог; пустая строка — ничего не расслышано.
  ///
  /// [patience] — продолжение разговора: начала речи ждут столько, а
  /// тишина до неё — не конец фразы. Без него молчание в 2,4 с — уже итог.
  ///
  /// Бросает [JarvisListenerFailure], если микрофон недоступен.
  Future<String> listen({
    void Function(String text)? onPartial,
    Duration? patience,
  });

  /// Дослушать досрочно: [listen] вернёт то, что уже распознано.
  Future<void> stop();

  /// Прервать без результата: [listen] вернёт пустую строку.
  Future<void> cancel();

  /// Слушает без остановки — так ждут имя «Джарвис». Каждая законченная
  /// фраза уходит в [onPhrase], текст по ходу — в [onPartial]. Разрешение на
  /// микрофон здесь не спрашивается: нет его — false, и молча.
  Future<bool> startContinuous({
    required void Function(String text) onPhrase,
    void Function(String text)? onPartial,
  });

  Future<void> stopContinuous();

  /// Слушает ли без остановки прямо сейчас.
  bool get continuous;

  void dispose();
}

/// Почему не получилось слушать — словами для человека.
class JarvisListenerFailure implements Exception {
  const JarvisListenerFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

final jarvisListenerProvider = Provider<JarvisListener?>((ref) {
  final listener = createJarvisListener();
  ref.onDispose(() => listener?.dispose());
  return listener;
});
