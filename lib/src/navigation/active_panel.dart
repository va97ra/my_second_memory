import 'app_destination.dart';

/// Какой пункт нижней панели подсвечен на этом адресе.
///
/// Пункт — свойство адреса, а не страницы: одну и ту же запись открывают и из
/// ленты, и из календаря, и различает их только адрес. Спрошенный явно
/// (`?panel=`) сильнее таблицы: он помнит, откуда пришли.
///
/// `null` — адрес ничей, и панель подсветит свой первый пункт.
String? panelIdForLocation(Uri location) {
  final asked = location.queryParameters['panel'];
  if (asked != null && asked.isNotEmpty) return asked;

  final path = location.path;
  return switch (path) {
    '/' => 'feed',
    '/memory' || '/security' => 'settings',
    '/memory/new' => 'calendar',
    '/memory/note/new' => 'add_note',
    _ when path.startsWith('/calendar') => 'calendar',
    _ when path.startsWith('/accounts') => 'accounts',
    _ when path.startsWith('/settings') => 'settings',
    _ when path.startsWith('/memory') => 'feed',
    _ => null,
  };
}

/// Какой пункт верхней панели подсвечен на этом адресе.
///
/// Инструмент занимает весь адрес целиком, поэтому ему хватает точного
/// совпадения: у страницы инструмента нет ни вложенных экранов, ни хвостов.
/// Вкладка оболочки с кнопкой наверху (настройки) подсвечивается так же, как
/// подсвечивалась бы внизу, — по своему разделу, вместе с вложенными
/// страницами: графиками смен, резервными копиями, архивом.
String? toolIdForLocation(Uri location, List<AppDestination> tools) {
  for (final tool in tools) {
    final active = tool.isBranch
        ? panelIdForLocation(location) == tool.id
        : tool.location == location.path;
    if (active) return tool.id;
  }
  return null;
}
