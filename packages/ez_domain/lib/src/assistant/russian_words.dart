/// Мелочи русского языка, на которых стоит разбор фраз Джарвиса.
///
/// `\b` и `\w` в Dart знают только латиницу, поэтому границы слова здесь
/// записаны явно: без них «встреча» находилась бы внутри «невстречались».
library;

/// Начало слова: перед ним нет буквы или цифры.
const wordStart = r'(?<![а-яa-z0-9])';

/// Конец слова: за ним нет буквы или цифры.
const wordEnd = r'(?![а-яa-z0-9])';

/// Регулярное выражение для разбора фраз: всегда с поддержкой Юникода.
RegExp phrasePattern(String pattern) => RegExp(pattern, unicode: true);

/// Рабочая копия фразы: нижний регистр, «ё» как «е».
///
/// Длина строки не меняется — каждой букве оригинала соответствует ровно одна
/// буква копии. На этом держится [PhraseScan]: найденное в копии вырезается
/// из оригинала по тем же позициям.
String normalizePhrase(String text) {
  final buffer = StringBuffer();
  for (final char in text.split('')) {
    var lower = char.toLowerCase();
    if (lower.length != 1) lower = char;
    buffer.write(lower == 'ё' ? 'е' : lower);
  }
  return buffer.toString();
}

String capitalizeFirst(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

/// Первая буква строчная, если дальше обычное слово: «Получить паспорт» →
/// «получить паспорт», но «МФЦ» остаётся «МФЦ».
String lowerFirst(String text) {
  if (text.length < 2 || text[1].toUpperCase() == text[1]) return text;
  return text[0].toLowerCase() + text.substring(1);
}

/// «a, b и c».
String joinWithAnd(List<String> parts) => parts.length < 2
    ? parts.join()
    : '${parts.sublist(0, parts.length - 1).join(', ')} и ${parts.last}';

/// Текст фразы, сжатый в одну строку.
String compactPhrase(String text) =>
    text.replaceAll(RegExp(r'\s+'), ' ').trim();

/// Фраза разобрана на поиск: каждое слово без окончания.
///
/// Русские слова склоняются: «перенеси врача» ищет запись «Врач», «про
/// счётчики» — «Замена счётчика». Окончание отрезается грубо — до основы в
/// четыре буквы, короткие слова остаются целыми. Ложных находок от этого
/// немного: запрос — это несколько слов, и совпасть должны все.
List<String> searchStems(String text) => [
      for (final word in normalizePhrase(text).split(RegExp('[^а-яa-z0-9]+')))
        if (word.length > 1) _stem(word),
    ];

String _stem(String word) {
  if (word.length <= 4) return word;
  final cut = word.length >= 7 ? 2 : 1;
  return word.substring(0, word.length - cut);
}
