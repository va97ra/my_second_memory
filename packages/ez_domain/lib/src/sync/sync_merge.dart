/// Слияние привезённого синхронизацией с тем, что успело измениться, пока она
/// ехала.
///
/// [baseline] — снимок, снятый до прогона. Из него следуют оба правила:
///
/// - строка, которая была в снимке, но исчезла из [current], удалена человеком
///   во время прогона; возвращать её из привезённого нельзя;
/// - строка, изменённая во время прогона, побеждает привезённую, если та не
///   новее.
///
/// Правило одно на все виды данных, поэтому живёт здесь, а не в контроллерах:
/// шесть копий расходятся по одной, и синхронизация начинает вести себя
/// по-разному для записей, повторов и расчётов.
List<T> mergeSyncedEntities<T>({
  required List<T> incoming,
  required List<T> current,
  required List<T> baseline,
  required String Function(T) idOf,
  required DateTime Function(T) updatedAtOf,
}) {
  final mergedById = {for (final item in incoming) idOf(item): item};
  final currentById = {for (final item in current) idOf(item): item};
  final baselineById = {for (final item in baseline) idOf(item): item};
  for (final id in baselineById.keys) {
    if (!currentById.containsKey(id)) mergedById.remove(id);
  }
  for (final item in currentById.values) {
    final id = idOf(item);
    final before = baselineById[id];
    final changedDuringSync =
        before == null || updatedAtOf(item).isAfter(updatedAtOf(before));
    if (!changedDuringSync) continue;
    final incomingItem = mergedById[id];
    if (incomingItem == null ||
        !updatedAtOf(incomingItem).isAfter(updatedAtOf(item))) {
      mergedById[id] = item;
    }
  }
  return mergedById.values.toList(growable: false);
}
