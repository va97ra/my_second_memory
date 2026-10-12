import 'package:ez_domain/ez_domain.dart';

/// Чем закончилась команда: что сказать и что ещё можно сделать после.
class JarvisOutcome {
  const JarvisOutcome(
    this.say, {
    this.open,
    this.link,
    this.undo,
    this.mentioned,
    this.followUp,
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

  /// Джарвис спросил и ждёт ответа — что с ним сделать. Null из функции:
  /// фраза оказалась не ответом и разбирается как обычно.
  final Future<JarvisOutcome?> Function(String said, DateTime now)? followUp;

  /// То же, но с вопросом, ответ на который ждёт [next].
  JarvisOutcome awaiting(
          Future<JarvisOutcome?> Function(String said, DateTime now) next) =>
      JarvisOutcome(
        say,
        open: open,
        link: link,
        undo: undo,
        mentioned: mentioned,
        followUp: next,
      );
}
