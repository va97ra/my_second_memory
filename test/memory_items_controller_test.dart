import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/data/memory_repository.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_item.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_status.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_type.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ezhednevnik_v2/src/features/notifications/data/notification_service.dart';

class _MemoryRepository implements MemoryRepository {
  _MemoryRepository(this.items);

  List<MemoryItem> items;

  @override
  Future<List<MemoryItem>> loadItems() async => items;

  @override
  Future<void> saveItems(List<MemoryItem> items) async {
    this.items = items;
  }
}

class _ReminderScheduler implements ReminderScheduler {
  final scheduled = <String>[];
  final cancelled = <String>[];
  List<String> reconciled = const [];

  @override
  bool get isSupported => true;

  @override
  Stream<String> get openedItemIds => const Stream.empty();

  @override
  Future<void> cancel(String itemId) async => cancelled.add(itemId);

  @override
  Future<void> initialize() async {}

  @override
  Future<void> reconcile(List<MemoryItem> items) async {
    reconciled = items.map((item) => item.id).toList();
  }

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<void> schedule(MemoryItem item) async => scheduled.add(item.id);

  @override
  Future<ReminderSoundSelection?> selectSound({String? currentUri}) async =>
      null;
}

void main() {
  test('delete removes item from state and repository', () async {
    final date = DateTime(2026, 6, 30);
    final repository = _MemoryRepository([
      MemoryItem(
        id: 'keep',
        type: MemoryType.note,
        title: 'Keep',
        memoryDate: date,
        createdAt: date,
        updatedAt: date,
      ),
      MemoryItem(
        id: 'delete',
        type: MemoryType.note,
        title: 'Delete',
        memoryDate: date,
        createdAt: date,
        updatedAt: date,
      ),
    ]);
    final controller = MemoryItemsController(repository);

    await controller.load();
    await controller.delete('delete');

    expect(controller.state.map((item) => item.id), ['keep']);
    expect(repository.items.map((item) => item.id), ['keep']);
  });

  test('toggleDone switches active and done states', () async {
    final date = DateTime(2026, 6, 30);
    final repository = _MemoryRepository([
      MemoryItem(
        id: 'toggle',
        type: MemoryType.note,
        title: 'Toggle',
        memoryDate: date,
        createdAt: date,
        updatedAt: date,
      ),
    ]);
    final controller = MemoryItemsController(repository);

    await controller.load();
    await controller.toggleDone('toggle');

    expect(controller.state.single.status, MemoryStatus.done);
    expect(repository.items.single.status, MemoryStatus.done);

    await controller.toggleDone('toggle');

    expect(controller.state.single.status, MemoryStatus.active);
    expect(repository.items.single.status, MemoryStatus.active);
  });

  test('restore returns archived item to active state', () async {
    final date = DateTime(2026, 6, 30);
    final repository = _MemoryRepository([
      MemoryItem(
        id: 'archived',
        type: MemoryType.note,
        title: 'Archived',
        memoryDate: date,
        createdAt: date,
        updatedAt: date,
        status: MemoryStatus.archived,
      ),
    ]);
    final controller = MemoryItemsController(repository);

    await controller.load();
    await controller.restore('archived');

    expect(controller.state.single.status, MemoryStatus.active);
    expect(repository.items.single.status, MemoryStatus.active);
  });

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
    final repository = _MemoryRepository([item]);
    final reminders = _ReminderScheduler();
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
}
