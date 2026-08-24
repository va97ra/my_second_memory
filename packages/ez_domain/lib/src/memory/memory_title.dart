import 'memory_type.dart';

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
  final compact = body.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (compact.isEmpty) return type.label(languageCode);
  if (compact.length <= 48) return compact;
  return '${compact.substring(0, 48)}...';
}
