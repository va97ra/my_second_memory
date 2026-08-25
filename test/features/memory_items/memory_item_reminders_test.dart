
import 'package:flutter_test/flutter_test.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';

import '../../support/memory_items_test_support.dart';

void main() {
  test('reminder is scheduled and cancelled with record lifecycle', () async {
    final now = DateTime.now();
    final item = MemoryItem(
      id: 'reminder',
      type: MemoryType.event,
      title: 'Встреча',
      memoryDate: DateTime(now.year, now.month, now.day + 1),
      createdAt: now,
      updatedAt: now,
      remindAt: now.add(const Duration(days: 1)),
    );
    final repository = FakeMemoryRepository([item]);
    final reminders = FakeReminderScheduler();
    final controller = MemoryItemsController(repository, reminders);

    await controller.load();
    await controller.update(item.copyWith(title: 'Новая встреча'));
    expect(reminders.scheduled, contains('reminder'));

    await controller.toggleDone('reminder');
    expect(reminders.cancelled, contains('reminder'));

    await controller.toggleDone('reminder');
    expect(reminders.scheduled.where((id) => id == 'reminder').length, 2);

    await controller.archive('reminder');
    await controller.delete('reminder');
    expect(reminders.cancelled.where((id) => id == 'reminder').length, 3);
  });

  // docs/behavior.md: восстановление возвращает напоминание, если оно ещё
  // впереди, и не воскрешает прошедшее.

  test('restore brings back a reminder only while it is still ahead',
      () async {
    final now = DateTime.now();
    final ahead = MemoryItem(
      id: 'ahead',
      type: MemoryType.event,
      title: 'Впереди',
      memoryDate: DateTime(now.year, now.month, now.day + 1),
      createdAt: now,
      updatedAt: now,
      status: MemoryStatus.archived,
      remindAt: now.add(const Duration(days: 1)),
    );
    final passed = ahead.copyWith(
      id: 'passed',
      title: 'Позади',
      remindAt: now.subtract(const Duration(days: 1)),
    );
    final reminders = FakeReminderScheduler();
    final controller = MemoryItemsController(
      FakeMemoryRepository([ahead, passed]),
      reminders,
    );
    await controller.load();

    await controller.restore('ahead');
    await controller.restore('passed');

    expect(reminders.scheduled, contains('ahead'));
    expect(reminders.scheduled, isNot(contains('passed')));
    expect(
      controller.items.every((item) => item.status == MemoryStatus.active),
      isTrue,
    );
  });

  // docs/behavior.md: архив хранит запись целиком, а не прячет её содержимое.

  test('archiving keeps the record whole, media included', () async {
    final now = DateTime.now();
    final item = MemoryItem(
      id: 'with-media',
      type: MemoryType.note,
      title: 'С фотографией',
      body: 'С фотографией',
      memoryDate: now,
      createdAt: now,
      updatedAt: now,
      imagePaths: const ['photo.jpg'],
      audioPath: 'voice.m4a',
    );
    final media = TrackingMediaStorage();
    final controller = MemoryItemsController(
      FakeMemoryRepository([item]),
      FakeReminderScheduler(),
      media,
    );
    await controller.load();

    await controller.archive('with-media');

    final archived = controller.items.single;
    expect(archived.status, MemoryStatus.archived);
    expect(archived.imagePaths, ['photo.jpg']);
    expect(archived.audioPath, 'voice.m4a');
    expect(media.deleted, isEmpty);
  });

  test('undated note never creates a reminder', () async {
    final now = DateTime.now();
    final note = MemoryItem(
      id: 'undated-note',
      type: MemoryType.note,
      title: 'Карта дочери',
      memoryDate: DateTime(now.year, now.month, now.day),
      createdAt: now,
      updatedAt: now,
      isUndated: true,
    );
    final repository = FakeMemoryRepository(const []);
    final reminders = FakeReminderScheduler();
    final controller = MemoryItemsController(repository, reminders);

    await controller.load();
    await controller.add(note);
    await controller.update(note.copyWith(body: 'Новые данные'));

    expect(reminders.scheduled, isEmpty);
    expect(repository.items.single.isUndated, isTrue);
  });
}
