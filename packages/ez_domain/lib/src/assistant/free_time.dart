import '../language/russian_plural.dart';
import '../memory/memory_item.dart';
import 'russian_words.dart';
import 'spoken_moments.dart';

/// Свободное время и ближайшее дело — ответы по календарю, без нейросети.
///
/// День считается с 8 утра до 10 вечера: ночь — не «окно». Дело без
/// времени окна не занимает, дело без конца — полчаса, как на шкале дня.
abstract final class FreeTime {
  static const dayStart = 8 * 60;
  static const dayEnd = 22 * 60;

  /// Окно короче часа — не окно: туда ничего не впишешь.
  static const shortest = 60;

  /// Свободные промежутки дня в минутах от полуночи. Сегодня — от «сейчас».
  static List<(int, int)> windows(
    List<MemoryItem> items, {
    required DateTime day,
    required DateTime now,
  }) {
    final today =
        day.year == now.year && day.month == now.month && day.day == now.day;
    var from = today ? _max(dayStart, now.hour * 60 + now.minute) : dayStart;
    final busy = [
      for (final item in items)
        if (item.timeMinutes case final start? when !item.isDone)
          (start, item.endMinutes ?? start + 30),
    ]..sort((left, right) => left.$1.compareTo(right.$1));
    final free = <(int, int)>[];
    for (final (start, end) in busy) {
      if (start - from >= shortest) free.add((from, start));
      from = _max(from, end);
    }
    if (dayEnd - from >= shortest) free.add((from, dayEnd));
    return free;
  }

  /// «Завтра свободно с 8 утра до 10 и с 11 до 10 вечера.»
  static String dayReply({
    required String label,
    required List<(int, int)> windows,
    required List<String> shifts,
    required int timed,
  }) {
    final day = capitalizeFirst(label);
    final shift =
        shifts.isEmpty ? '' : '$day у вас смена: ${joinWithAnd(shifts)}. ';
    if (windows.isEmpty) {
      final when = shift.isEmpty ? '${lowerFirst(label)} ' : '';
      return '$shiftСвободного окна $whenнет: всё занято.';
    }
    if (timed == 0 && shifts.isEmpty) return '$day вы свободны весь день.';
    final spans = [
      for (final (start, end) in windows)
        'с ${spokenClock(start)} до ${spokenClock(end)}',
    ];
    return '$shift${shift.isEmpty ? '$day свободно' : 'По делам свободно'} '
        '${joinWithAnd(spans)}.';
  }

  /// Свободные дни периода: без смен и без дел со временем. Нет таких —
  /// самый спокойный день.
  static String rangeReply({
    required String label,
    required List<({DateTime day, int timed, bool shift})> days,
    required DateTime now,
  }) {
    final free = [
      for (final day in days)
        if (day.timed == 0 && !day.shift) day.day,
    ];
    final period = capitalizeFirst(label);
    if (free.isNotEmpty) {
      final named = free.take(4).map((day) => spokenWhen(day, now));
      final more = free.length > 4 ? ' и ещё ${free.length - 4}' : '';
      return free.length == 1
          ? '$period свободен один день: ${named.single}.'
          : '$period свободны: ${named.join(', ')}$more.';
    }
    final calm = [...days]
      ..sort((left, right) => left.timed.compareTo(right.timed));
    final best = calm.first;
    return '$period свободных дней нет. Спокойнее всего '
        '${spokenWhen(best.day, now)}: '
        '${best.timed == 0 ? 'только смена' : '${best.timed} ${russianPlural(best.timed, 'дело', 'дела', 'дел')} со временем'}.';
  }

  /// «Дальше — врач, сегодня в 4 часа дня.»
  static String nextReply(MemoryItem? item, DateTime now) {
    if (item == null) {
      return 'Дальше дел со временем нет — ни сегодня, ни в ближайшие две недели.';
    }
    return 'Дальше — ${lowerFirst(item.title)}, '
        '${spokenMoment(item.memoryDate, item.timeMinutes, now)}.';
  }

  static int _max(int left, int right) => left > right ? left : right;
}
