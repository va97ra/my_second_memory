import '../memory/memory_item.dart';
import '../memory/memory_status.dart';
import 'russian_words.dart';

/// Записи, о которых говорит человек: «перенеси врача», «отметь зарядку».
///
/// Слова запроса сравниваются по основам: «врача» находит «Врач». Первой
/// идёт та запись, которую скорее всего имеют в виду: ближайшая впереди, а
/// если впереди ничего нет — самая недавняя. Уже выполненные и архивные
/// уходят в конец: о них говорят реже.
List<MemoryItem> findRecordsByWords(
  Iterable<MemoryItem> items,
  String query, {
  required DateTime now,
}) {
  final stems = searchStems(query);
  if (stems.isEmpty) return const [];
  final found = [
    for (final item in items)
      if (_matches(item, stems)) item,
  ];
  final today = DateTime(now.year, now.month, now.day);
  int rank(MemoryItem item) {
    if (item.status != MemoryStatus.active) return 2;
    return item.isUndated || !item.memoryDate.isBefore(today) ? 0 : 1;
  }

  found.sort((left, right) {
    final byRank = rank(left).compareTo(rank(right));
    if (byRank != 0) return byRank;
    final byDay = left.memoryDate.compareTo(right.memoryDate);
    // Впереди — ближайшая первой, позади — самая недавняя первой.
    final ahead = rank(left) == 0;
    if (byDay != 0) return ahead ? byDay : -byDay;
    return (left.timeMinutes ?? 0).compareTo(right.timeMinutes ?? 0);
  });
  return found;
}

bool _matches(MemoryItem item, List<String> stems) {
  final text = normalizePhrase('${item.title}\n${item.plainBody}');
  return stems.every(text.contains);
}
