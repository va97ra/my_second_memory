import 'russian_words.dart';

/// Как распознавание речи пишет «Джарвис».
///
/// Имени нет в словаре модели, и она подбирает похожее: «джарвис»,
/// «джералд», «джентль», «джарс», «джарлис», «жардж», «эйджарвес» —
/// проверено голосом владельца в MemoryVoice. Распознавание Google пишет
/// имя правильно, а иногда латиницей — «Jarvis». Описано одно на всё: им
/// узнают вызов и его же отрезают от просьбы в разборе фраз.
const jarvisNamePattern =
    '(?:эй)?(?:дж[аеи][рнл][а-я]{0,4}|жар[лвд][а-я]{0,3}|дарвис|jarvis)';

/// Имя «Джарвис» в услышанной фразе и просьба после него.
abstract final class WakeWord {
  /// Именем считается только первое слово фразы (можно после «эй», «ну»):
  /// так зовут, а в середине обычного разговора эти звуки не мешают —
  /// «позвони Джарвису» не вызов.
  static final _name = phrasePattern(
      '^(?:(?:эй|ну|слушай)\\s+)?$jarvisNamePattern$wordEnd');

  /// null — имени нет; '' — позвали без просьбы; иначе — просьба после имени.
  static String? commandAfter(String text) {
    final work = normalizePhrase(text.trim());
    final match = _name.firstMatch(work);
    if (match == null) return null;
    return text
        .trim()
        .substring(match.end)
        .replaceFirst(RegExp(r'^[\s,.!?:;—-]+'), '')
        .trim();
  }

  static final _stop = phrasePattern('^(?:спасибо|благодарю|все|хватит|отбой'
      '|пока|ничего|не\\s+надо|до\\s+свидания|свободен)$wordEnd');

  /// «Спасибо», «всё», «хватит» — разговор закончен, дальше — только по
  /// имени.
  static bool endsConversation(String text) =>
      _stop.hasMatch(normalizePhrase(text.trim()));
}
