import 'package:ez_domain/ez_domain.dart';

/// Час шкалы дня в пикселях. От него считается всё остальное.
const double dayTimelineHourHeight = 64;

/// Шаг перетаскивания и наименьшая длительность таблички — четверть часа.
///
/// Меньше нельзя не из-за пикселей, а потому что на четверти часа подпись
/// умещается в одну строку, а на пяти минутах уже нет.
const int dayTimelineStepMinutes = 15;

/// Полоса с часами слева.
const double dayTimelineGutterWidth = 52;

/// Сдвиг вложенной таблички. Наехавшая ложится поверх и правее, как в
/// календарях: делить ширину пополам нельзя — у смены внутри может лежать
/// весь день, и обе половины станут нечитаемыми.
const double dayTimelineCascadeIndent = 18;

const int _minutesInDay = 24 * 60;

/// Минуты от полуночи → отступ сверху.
double dayTimelineOffsetOf(int minutes) =>
    minutes / 60 * dayTimelineHourHeight;

/// Отступ сверху → минуты, прижатые к шагу шкалы.
int dayTimelineMinutesAt(double offset) {
  final raw = offset / dayTimelineHourHeight * 60;
  final snapped = (raw / dayTimelineStepMinutes).round() * dayTimelineStepMinutes;
  return snapped.clamp(0, _minutesInDay);
}

/// Конец записи на шкале.
///
/// У записи без конца его нет и в модели: на шкале она занимает наименьшую
/// табличку, чтобы её было куда нажать.
int dayTimelineEndOf(MemoryItem item) {
  final start = item.timeMinutes;
  if (start == null) return 0;
  final end = item.endMinutes ?? start + dayTimelineStepMinutes;
  return end.clamp(start + dayTimelineStepMinutes, _minutesInDay);
}

/// Табличка на шкале: запись, её границы и глубина каскада.
class DayTimelineBlock {
  const DayTimelineBlock({
    required this.item,
    required this.start,
    required this.end,
    required this.depth,
  });

  final MemoryItem item;
  final int start;
  final int end;

  /// Сколько табличек уже идёт под этой. Ноль — лежит на самой бумаге.
  final int depth;

  double get top => dayTimelineOffsetOf(start);
  double get height => dayTimelineOffsetOf(end) - dayTimelineOffsetOf(start);
  double get indent => depth * dayTimelineCascadeIndent;
}

/// Раскладывает записи дня по шкале.
///
/// Порядок важен: при одинаковом начале длинная ложится первой, короткая
/// поверх неё. Иначе смена накрыла бы собой все дела внутри себя.
List<DayTimelineBlock> layOutDayTimeline(Iterable<MemoryItem> items) {
  final timed = items.where((item) => item.timeMinutes != null).toList()
    ..sort((a, b) {
      final byStart = a.timeMinutes!.compareTo(b.timeMinutes!);
      if (byStart != 0) return byStart;
      return dayTimelineEndOf(b).compareTo(dayTimelineEndOf(a));
    });

  final blocks = <DayTimelineBlock>[];
  for (final item in timed) {
    final start = item.timeMinutes!;
    final depth = blocks
        .where((placed) => placed.start <= start && placed.end > start)
        .length;
    blocks.add(
      DayTimelineBlock(
        item: item,
        start: start,
        end: dayTimelineEndOf(item),
        depth: depth,
      ),
    );
  }
  return blocks;
}

/// Час в полосе слева: всегда две цифры, чтобы столбик стоял ровно.
String formatDayTimelineHour(int hour) =>
    '${hour.toString().padLeft(2, '0')}:00';

/// Отрезок рамки под пальцем: «09:30 – 15:15».
String formatDayTimelineRange(int start, int end) =>
    '${_hhmm(start)} – ${_hhmm(end)}';

String _hhmm(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
    '${(minutes % 60).toString().padLeft(2, '0')}';
