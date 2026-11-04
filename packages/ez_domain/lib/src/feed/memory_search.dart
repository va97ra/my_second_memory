import 'package:meta/meta.dart';

import '../memory/memory_item.dart';

/// Строка поиска страницы: открыта ли и что в ней набрано. Одна на ленту и
/// записки.
@immutable
class MemorySearchBar {
  const MemorySearchBar({this.isOpen = false, this.query = ''});

  final bool isOpen;

  /// Что ищут. Живёт только при открытой строке.
  final String query;

  /// Ищет ли страница прямо сейчас: пустая строка ничего не ищет, и под ней
  /// обычное содержимое — иначе прошлые находки казались бы новыми.
  bool get hasQuery => isOpen && !MemorySearch(query).isEmpty;

  /// Каждый вход начинается с пустой строки: прошлый запрос, всплывший сам,
  /// выглядел бы как правка.
  MemorySearchBar toggled() => MemorySearchBar(isOpen: !isOpen);

  MemorySearchBar withQuery(String value) =>
      isOpen ? MemorySearchBar(isOpen: true, query: value) : this;
}

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
