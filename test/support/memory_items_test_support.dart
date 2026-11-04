import 'dart:async';

import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';

/// Поддельные хранилище, будильник и медиа для тестов записей.
class FakeMemoryRepository implements MemoryRepository {
  FakeMemoryRepository(this.items);

  List<MemoryItem> items;
  final upsertedIds = <String>[];
  final deletedIds = <String>[];
  int replaceAllCount = 0;
  int upsertAllCount = 0;

  @override
  Future<List<MemoryItem>> loadAll() async => items;

  @override
  Future<void> upsert(MemoryItem item) async {
    upsertedIds.add(item.id);
    items = [
      for (final existing in items)
        if (existing.id == item.id) item else existing,
      if (!items.any((existing) => existing.id == item.id)) item,
    ];
  }

  @override
  Future<void> upsertAll(List<MemoryItem> incoming) async {
    upsertAllCount++;
    upsertedIds.addAll(incoming.map((item) => item.id));
    final byId = {
      for (final item in items) item.id: item,
      for (final item in incoming) item.id: item,
    };
    items = byId.values.toList();
  }

  @override
  Future<void> delete(String id) async {
    deletedIds.add(id);
    items = [
      for (final item in items)
        if (item.id != id) item
    ];
  }

  @override
  Future<void> replaceAll(List<MemoryItem> items) async {
    replaceAllCount++;
    this.items = items;
  }

  @override
  Future<void> close() async {}
}

class DelayedMemoryRepository extends FakeMemoryRepository {
  DelayedMemoryRepository(super.items);

  final firstWriteStarted = Completer<void>();
  final releaseFirstWrite = Completer<void>();
  final writtenBodies = <String>[];

  @override
  Future<void> upsert(MemoryItem item) async {
    if (writtenBodies.isEmpty) {
      firstWriteStarted.complete();
      await releaseFirstWrite.future;
    }
    writtenBodies.add(item.body);
    await super.upsert(item);
  }
}

class FakeReminderScheduler implements ReminderScheduler {
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
  Future<void> reconcileRecurring(List<MemoryItem> items) async {}

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<List<ReminderSoundSelection>> systemSounds() async => const [];

  @override
  Future<void> schedule(MemoryItem item) async => scheduled.add(item.id);

  @override
  Future<ReminderSoundSelection?> selectSound({
    String? currentUri,
    ReminderSoundSource source = ReminderSoundSource.system,
  }) async =>
      null;
}

class TrackingMediaStorage extends MediaStorage {
  final deleted = <String>[];

  @override
  Future<void> deleteOwnedFiles(
    Iterable<String> paths, {
    required Set<String> usedPaths,
  }) async {
    deleted.addAll(paths.where((path) => !usedPaths.contains(path)));
  }
}
