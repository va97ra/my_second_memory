import 'russian_words.dart';

/// Фраза, из которой по очереди вынимают найденные куски.
///
/// Рабочая копия — в нижнем регистре и с «е» вместо «ё». Найденный кусок
/// забивается в ней пробелами, чтобы следующее правило его не увидело:
/// «через 2 часа» не должно потом ещё раз найтись как «2 часа дня». Что
/// осталось ненайденным — это и есть название дела.
class PhraseScan {
  PhraseScan(this.original)
      : work = normalizePhrase(original),
        _removed = List.filled(original.length, false);

  final String original;

  /// Рабочая копия: то, что ещё не вынуто.
  String work;
  final List<bool> _removed;

  /// Все совпадения с [pattern]; каждое вынимается из фразы.
  List<RegExpMatch> take(RegExp pattern) {
    final matches = pattern.allMatches(work).toList();
    if (matches.isEmpty) return matches;
    final chars = work.split('');
    for (final match in matches) {
      for (var i = match.start; i < match.end; i++) {
        chars[i] = ' ';
        _removed[i] = true;
      }
    }
    work = chars.join();
    return matches;
  }

  /// Есть ли совпадение с [pattern]; если есть — вынимается.
  bool takes(RegExp pattern) => take(pattern).isNotEmpty;

  /// Исходный текст без вынутых кусков.
  String remainder() {
    final buffer = StringBuffer();
    for (var i = 0; i < original.length; i++) {
      buffer.write(_removed[i] ? ' ' : original[i]);
    }
    return buffer.toString();
  }
}
