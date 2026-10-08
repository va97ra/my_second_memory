import 'package:ez_domain/ez_domain.dart';

/// Чем закончилась команда: что сказать и что ещё можно сделать после.
class JarvisOutcome {
  const JarvisOutcome(
    this.say, {
    this.open,
    this.link,
    this.undo,
    this.mentioned,
  });

  /// Ответ без обращения: «сэр» добавляется при выводе.
  final String say;

  /// Открыть страницу сразу: «открой календарь».
  final OpenPlace? open;

  /// Предложить страницу кнопкой под ответом: «Открыть день».
  final OpenPlace? link;

  /// Как вернуть всё назад, если человек скажет «отмени».
  final Future<void> Function()? undo;

  /// Запись, о которой шла речь: «перенеси её» дальше — про неё.
  final MemoryItem? mentioned;
}
