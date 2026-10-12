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

  /// Несколько действий по одной просьбе — один ответ и одна отмена на
  /// все: возвращается всё сделанное, в обратном порядке. Страница и
  /// запись — от последнего действия, где они есть.
  static JarvisOutcome merged(String say, List<JarvisOutcome> outcomes) {
    final undos = [
      for (final outcome in outcomes)
        if (outcome.undo != null) outcome.undo!,
    ];
    T? last<T>(T? Function(JarvisOutcome) of) {
      for (final outcome in outcomes.reversed) {
        if (of(outcome) case final value?) return value;
      }
      return null;
    }

    return JarvisOutcome(
      say,
      open: last((outcome) => outcome.open),
      link: last((outcome) => outcome.link),
      mentioned: last((outcome) => outcome.mentioned),
      undo: undos.isEmpty
          ? null
          : () async {
              for (final undo in undos.reversed) {
                await undo();
              }
            },
    );
  }

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
