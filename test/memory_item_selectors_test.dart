import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_item_selectors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MemoryItem item(String id, DateTime date, {bool isUndated = false}) {
    return MemoryItem(
      id: id,
      type: MemoryType.note,
      title: id,
      memoryDate: date,
      createdAt: date,
      updatedAt: date,
      isUndated: isUndated,
    );
  }

  test('indexes dated items once and excludes undated notes', () {
    final firstDate = DateTime(2026, 8, 18, 9);
    final secondDate = DateTime(2026, 8, 19, 14);
    final index = indexMemoryItemsByDate([
      item('first', firstDate),
      item('second', secondDate),
      item('same-day', firstDate.add(const Duration(hours: 3))),
      item('undated', firstDate, isUndated: true),
    ]);

    expect(
      index[memoryItemDateKey(firstDate)]?.map((entry) => entry.id),
      ['first', 'same-day'],
    );
    expect(index[memoryItemDateKey(secondDate)]?.single.id, 'second');
    expect(index.values.expand((items) => items).map((entry) => entry.id),
        isNot(contains('undated')));
    expect(
      () => index[memoryItemDateKey(firstDate)]!.clear(),
      throwsUnsupportedError,
    );
  });

  test('builds id, archive and sorted undated indexes in one pass', () {
    final date = DateTime(2026, 8, 18);
    final olderNote = item('older-note', date, isUndated: true);
    final newerNote = MemoryItem(
      id: 'newer-note',
      type: MemoryType.note,
      title: 'newer-note',
      memoryDate: date,
      createdAt: date,
      updatedAt: date.add(const Duration(hours: 1)),
      isUndated: true,
    );
    final archived = item('archived', date).copyWith(
      status: MemoryStatus.archived,
    );
    final reminder = item('reminder', date).copyWith(
      remindAt: date.add(const Duration(days: 2, hours: 9)),
    );

    final index =
        MemoryItemsIndex.build([olderNote, archived, newerNote, reminder]);

    expect(index.byId['archived'], same(archived));
    expect(index.archived, [archived]);
    expect(index.undatedNotes.map((entry) => entry.id), [
      'newer-note',
      'older-note',
    ]);
    expect(() => index.byId.clear(), throwsUnsupportedError);
    expect(() => index.undatedNotes.clear(), throwsUnsupportedError);
    expect(index.activeReminderDays, {
      memoryItemDateKey(reminder.remindAt!),
    });
  });

  test('an unrelated record does not notify an id-scoped subscriber', () {
    final date = DateTime(2026, 8, 18);
    final first = item('first', date);
    final second = item('second', date);
    final source = StateProvider<List<MemoryItem>>(
      (ref) => [first, second],
    );
    final container = ProviderContainer(
      overrides: [
        memoryItemsIndexProvider.overrideWith(
          (ref) => MemoryItemsIndex.build(ref.watch(source)),
        ),
      ],
    );
    addTearDown(container.dispose);

    var notifications = 0;
    final subscription = container.listen(
      memoryItemByIdProvider('first'),
      (_, __) => notifications++,
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    expect(notifications, 1);

    container.read(source.notifier).state = [
      first,
      second.copyWith(title: 'changed'),
    ];

    expect(container.read(memoryItemByIdProvider('first')), same(first));
    expect(notifications, 1);
  });
}
