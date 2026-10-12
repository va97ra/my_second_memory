import '../memory/memory_item.dart';

/// Поиск записи по словам.
///
/// Запись найдена, если в её заголовке или тексте встречается каждое слово
/// запроса — в любом порядке и как часть слова: «счетчик ленина» находит
/// «Замена счётчика, ул. Ленина». Регистр и разница между «ё» и «е» не
/// учитываются: человек набирает так, как удобно, а не так, как записал.
class MemorySearch {
  MemorySearch(String query)
      : _words = _normalize(query)
            .split(' ')
            .where((word) => word.isNotEmpty)
            .toList(growable: false);

  final List<String> _words;

  /// Пустой запрос ничего не отсеивает.
  bool get isEmpty => _words.isEmpty;

  bool matches(MemoryItem item) {
    if (_words.isEmpty) return true;
    // Перевод строки между заголовком и текстом не даёт слову склеиться из
    // конца одного и начала другого.
    final text = _normalize('${item.title}\n${item.plainBody}');
    return _words.every(text.contains);
  }

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll('ё', 'е')
      .replaceAll(RegExp(r'[ \t ]+'), ' ')
      .trim();
}
