import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ezhednevnik_v2/src/features/calendar/ui/widgets/day_timeline_geometry.dart';

MemoryItem _item(String id, int? start, [int? end]) {
  final date = DateTime(2026, 9, 2);
  return MemoryItem(
    id: id,
    type: MemoryType.task,
    title: id,
    memoryDate: date,
    createdAt: date,
    updatedAt: date,
    timeMinutes: start,
    endMinutes: end,
  );
}

void main() {
  test('dragging snaps to the quarter of an hour', () {
    expect(dayTimelineMinutesAt(dayTimelineOffsetOf(9 * 60 + 37)), 9 * 60 + 30);
    expect(dayTimelineMinutesAt(dayTimelineOffsetOf(9 * 60 + 38)), 9 * 60 + 45);
  });

  test('the scale never reaches past midnight', () {
    expect(dayTimelineMinutesAt(-40), 0);
    expect(dayTimelineMinutesAt(dayTimelineHourHeight * 30), 24 * 60);
  });

  test('a record without an end still takes the smallest block', () {
    expect(dayTimelineEndOf(_item('point', 9 * 60)), 9 * 60 + 15);
  });

  test('a record without a time is not on the scale at all', () {
    expect(layOutDayTimeline([_item('undated', null)]), isEmpty);
  });

  test('a shift keeps the day inside it and the day lies on top', () {
    final blocks = layOutDayTimeline([
      _item('task', 12 * 60, 13 * 60),
      _item('shift', 6 * 60, 18 * 60),
    ]);

    expect(blocks.map((block) => block.item.id), ['shift', 'task']);
    expect(blocks.first.depth, 0);
    expect(blocks.last.depth, 1);
    expect(blocks.last.indent, dayTimelineCascadeIndent);
  });

  test('two records at one hour cascade, they do not share the width', () {
    final blocks = layOutDayTimeline([
      _item('outer', 10 * 60, 14 * 60),
      _item('middle', 11 * 60, 13 * 60),
      _item('inner', 12 * 60, 12 * 60 + 30),
    ]);

    expect(blocks.map((block) => block.depth), [0, 1, 2]);
  });

  test('records that do not touch stay on the paper itself', () {
    final blocks = layOutDayTimeline([
      _item('morning', 9 * 60, 10 * 60),
      _item('evening', 18 * 60, 19 * 60),
    ]);

    expect(blocks.every((block) => block.depth == 0), isTrue);
  });

  test('the taller block is measured by its own hours', () {
    final block = layOutDayTimeline([_item('shift', 6 * 60, 18 * 60)]).single;

    expect(block.top, dayTimelineHourHeight * 6);
    expect(block.height, dayTimelineHourHeight * 12);
  });
}
