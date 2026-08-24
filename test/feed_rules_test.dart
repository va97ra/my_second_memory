import 'package:flutter_test/flutter_test.dart';
import 'package:ez_domain/ez_domain.dart';

void main() {
  test('smart feed includes today and overdue tasks', () {
    final today = DateTime(2026, 6, 30);
    final yesterday = DateTime(2026, 6, 29);
    final tomorrow = DateTime(2026, 7, 1);

    final items = [
      _item('1', MemoryType.task, yesterday, 'overdue'),
      _item('2', MemoryType.note, today, 'today note'),
      _item('3', MemoryType.event, tomorrow, 'future event'),
    ];

    final feed = smartFeedForDay(items, today);

    expect(feed.map((item) => item.id), ['1', '2']);
  });

  test('groupItemsByDate groups active records by memoryDate', () {
    final items = [
      _item('1', MemoryType.note, DateTime(2026, 6, 30), 'a'),
      _item('2', MemoryType.voiceNote, DateTime(2026, 6, 30), 'b'),
      _item('3', MemoryType.project, DateTime(2026, 7, 1), 'c'),
      _item(
        '4',
        MemoryType.note,
        DateTime(2026, 7, 2),
        'archived',
        status: MemoryStatus.archived,
      ),
    ];

    final groups = groupItemsByDate(items);

    expect(groups.length, 2);
    expect(groups.first.date, DateTime(2026, 7, 1));
    expect(groups.last.items.length, 2);
  });

  test('general feed excludes monthly and yearly recurring records', () {
    final date = DateTime(2026, 7, 20);
    final items = [
      _item('regular', MemoryType.note, date, 'regular'),
      _item(
        'monthly',
        MemoryType.payment,
        date,
        'monthly',
        repeatRule: 'monthly',
        seriesId: 'monthly-series',
      ),
      _item(
        'yearly',
        MemoryType.birthday,
        date,
        'yearly',
        repeatRule: 'yearly',
      ),
      _item('one-time-payment', MemoryType.payment, date, 'one time'),
    ];

    final groups = groupItemsByDate(items);

    expect(groups.single.items.map((item) => item.id), [
      'regular',
      'one-time-payment',
    ]);
  });

  test('calendar feed groups exclude undated notes', () {
    final date = DateTime(2026, 8, 13);
    final dated = _item('dated', MemoryType.note, date, 'dated');
    final undated = MemoryItem(
      id: 'undated',
      type: MemoryType.note,
      title: 'Карта дочери',
      memoryDate: date,
      createdAt: date,
      updatedAt: date,
      isUndated: true,
    );

    expect(groupItemsByDate([dated, undated]).single.items, [dated]);
    expect(smartFeedForDay([dated, undated], date), [dated]);
  });
}

MemoryItem _item(
  String id,
  MemoryType type,
  DateTime date,
  String title, {
  MemoryStatus status = MemoryStatus.active,
  String? repeatRule,
  String? seriesId,
}) {
  return MemoryItem(
    id: id,
    type: type,
    title: title,
    memoryDate: date,
    createdAt: date,
    updatedAt: date,
    status: status,
    repeatRule: repeatRule,
    seriesId: seriesId,
  );
}
