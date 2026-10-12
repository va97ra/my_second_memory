import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Где Джарвис сейчас на экране.
///
/// Решение владельца 12 октября 2026: перейдя на страницу или отозвавшись на
/// имя, Джарвис не закрывает страницу листом, а остаётся на ней маленьким
/// значком — слушает, говорит, и видно, что он делает.
enum JarvisPresence {
  /// Его нет: ждёт имени.
  away,

  /// Значок поверх страницы.
  badge,

  /// Лист разговора.
  sheet,
}

final jarvisPresenceProvider =
    StateProvider<JarvisPresence>((ref) => JarvisPresence.away);
