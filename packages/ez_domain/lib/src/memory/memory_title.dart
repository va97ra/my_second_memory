import 'memory_item.dart';
import 'memory_type.dart';
import 'styled_text.dart';

/// Название записи по её тексту.
///
/// Отдельного поля названия у записи нет: заголовком служит начало текста,
/// сжатое до одной строки. Пустая запись называется своим видом, чтобы в
/// списках она не была безымянной.
String memoryTitleFromRecord(
  String body,
  MemoryType type,
  String languageCode,
) {
  final title = _titleOf(StyledText.unstyled(body)).plain;
  return title.isEmpty ? type.label(languageCode) : title;
}

/// Название для карточки — с оформлением текста, из которого оно взято:
/// раскрашенное в редакторе остаётся раскрашенным в ленте и записках
/// (отзыв владельца 11 октября 2026). Название, которое не совпадает с
/// началом текста, показывается как есть.
StyledText styledMemoryTitle(MemoryItem item) {
  final title = item.title.trim();
  final styled = _titleOf(StyledText.parse(item.body));
  return styled.plain == title ? styled : StyledText.unstyled(title);
}

const _titleLength = 48;

/// Одна строка без лишних пробелов, не длиннее [_titleLength] знаков.
StyledText _titleOf(StyledText body) {
  final compact = body.collapsed();
  if (compact.plain.length <= _titleLength) return compact;
  final cut = compact.slice(0, _titleLength);
  return StyledText('${cut.plain}...', [
    ...cut.marksIn(0, _titleLength),
    for (var i = 0; i < 3; i++) TextMark.plain,
  ]);
}
