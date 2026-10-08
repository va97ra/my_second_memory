import 'russian_words.dart';
import 'wake_word.dart';

/// Фраза, обращённая к Джарвису, без обращения и вежливых слов в начале.
///
/// «Джарвис, пожалуйста, открой календарь» и «открой календарь» — одна и та
/// же команда. Распознавание голоса пишет имя на слух («джералд», «джарс»),
/// поэтому имя узнаётся по первому слову и в нескольких написаниях; дальше
/// по фразе «джентльмен» именем не считается.
class JarvisPhrase {
  factory JarvisPhrase(String raw) {
    final original = raw.trim();
    final lead = _lead.firstMatch(normalizePhrase(original));
    final rest = lead == null ? original : original.substring(lead.end);
    final text = rest.replaceFirst(RegExp(r'[\s.!?…]+$'), '').trim();
    return JarvisPhrase._(text, normalizePhrase(text), raw.trim());
  }

  const JarvisPhrase._(this.text, this.work, this.raw);

  /// Сказанное без обращения — с исходным регистром, для текста записей.
  final String text;

  /// То же в нижнем регистре и с «е» вместо «ё» — для распознавания.
  final String work;

  /// Сказанное целиком, как пришло.
  final String raw;

  bool get isEmpty => work.isEmpty;

  /// Был ли это вопрос: знак вопроса или вопросительное слово в начале.
  bool get isQuestion => raw.endsWith('?') || _questionWord.hasMatch(work);

  static final _lead = phrasePattern('^(?:(?:эй|ну|слушай|слушайте|$jarvisNamePattern'
      '|сэр|пожалуйста|будь\\s+добр|будьте\\s+добры)$wordEnd[\\s,.!]*)+');

  static final _questionWord = phrasePattern('^(?:как|почему|зачем|кто|что'
      '\\s+такое|где|откуда|куда|какой|какая|какое|какие|сколько|когда|ли)'
      '$wordEnd');
}
