import 'dart:convert';

/// Разница между тем, что лежит в хранилище, и тем, что должно лежать.
final class ListChanges<T> {
  const ListChanges({required this.upserts, required this.removedIds});

  /// Новые и изменившиеся.
  final List<T> upserts;

  /// Те, которых в новом списке нет.
  final List<String> removedIds;

  bool get isEmpty => upserts.isEmpty && removedIds.isEmpty;
}

/// Что записать и что удалить, чтобы хранилище со списком [before] стало
/// списком [after].
///
/// Вещь изменилась, если изменилось хоть что-то из того, что попадает в
/// хранилище, — то есть её JSON. Сравнивать только время правки нельзя:
/// ремонт данных прошлых версий поправляет записи, не трогая его, и такая
/// правка молча пропала бы при следующем запуске. Тот же самый объект не
/// сравнивается вовсе: слияние оставляет нетронутые вещи прежними объектами.
ListChanges<T> listChanges<T>({
  required Iterable<T> before,
  required Iterable<T> after,
  required String Function(T item) idOf,
  required Map<String, Object?> Function(T item) toJson,
}) {
  bool same(T stored, T next) =>
      identical(stored, next) ||
      jsonEncode(toJson(stored)) == jsonEncode(toJson(next));

  final storedById = {for (final item in before) idOf(item): item};
  final afterIds = <String>{};
  final upserts = <T>[];
  for (final item in after) {
    final id = idOf(item);
    afterIds.add(id);
    final stored = storedById[id];
    if (stored == null || !same(stored, item)) upserts.add(item);
  }
  return ListChanges(
    upserts: upserts,
    removedIds: [
      for (final id in storedById.keys)
        if (!afterIds.contains(id)) id,
    ],
  );
}
