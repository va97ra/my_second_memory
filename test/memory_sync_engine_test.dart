import 'dart:async';

import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_item.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_type.dart';
import 'package:ezhednevnik_v2/src/features/security/data/app_cipher.dart';
import 'package:ezhednevnik_v2/src/features/sync/data/sync_local_store.dart';
import 'package:ezhednevnik_v2/src/features/sync/data/sync_remote_store.dart';
import 'package:ezhednevnik_v2/src/features/sync/domain/memory_sync_engine.dart';
import 'package:ezhednevnik_v2/src/features/sync/domain/sync_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pre-existing records on two devices are merged into one union',
      () async {
    final server = _SyncServer();
    final remoteWindows = _FakeRemoteStore(server);
    final remoteAndroid = _FakeRemoteStore(server);
    final key = List<int>.generate(32, (index) => index + 1);
    final windowsCipher = AppCipher.fromKeyBytes(key);
    final androidCipher = AppCipher.fromKeyBytes(key);
    final windowsTombstones = _MemoryTombstoneStore();
    final androidTombstones = _MemoryTombstoneStore();
    addTearDown(windowsCipher.destroy);
    addTearDown(androidCipher.destroy);
    final createdAt = DateTime.utc(2026, 8, 18, 8);
    var windowsItems = [_item('windows', 'Windows record', createdAt)];
    var androidItems = [
      _item(
        'android',
        'Android record',
        createdAt.add(const Duration(minutes: 1)),
      ),
    ];

    await MemorySyncEngine(
      remote: remoteWindows,
      cipher: windowsCipher,
      tombstones: windowsTombstones,
    ).synchronize(
      localItems: windowsItems,
      replaceLocal: (items) async => windowsItems = items,
    );
    await MemorySyncEngine(
      remote: remoteAndroid,
      cipher: androidCipher,
      tombstones: androidTombstones,
    ).synchronize(
      localItems: androidItems,
      replaceLocal: (items) async => androidItems = items,
    );
    await MemorySyncEngine(
      remote: remoteWindows,
      cipher: windowsCipher,
      tombstones: windowsTombstones,
    ).synchronize(
      localItems: windowsItems,
      replaceLocal: (items) async => windowsItems = items,
    );

    expect(windowsItems.map((item) => item.id),
        unorderedEquals(['windows', 'android']));
    expect(androidItems.map((item) => item.id),
        unorderedEquals(['windows', 'android']));
    expect(server.entities.map((entity) => entity.entityId),
        unorderedEquals(['windows', 'android']));
  });

  test('two devices exchange edits and deletion tombstones', () async {
    final server = _SyncServer();
    final remoteA = _FakeRemoteStore(server);
    final remoteB = _FakeRemoteStore(server);
    final key = List<int>.generate(32, (index) => index + 1);
    final cipherA = AppCipher.fromKeyBytes(key);
    final cipherB = AppCipher.fromKeyBytes(key);
    final tombstonesA = _MemoryTombstoneStore();
    final tombstonesB = _MemoryTombstoneStore();
    addTearDown(cipherA.destroy);
    addTearDown(cipherB.destroy);
    final createdAt = DateTime.utc(2026, 8, 18, 8);
    var itemsA = [_item('shared', 'Windows note', createdAt)];
    var itemsB = <MemoryItem>[];

    await MemorySyncEngine(
      remote: remoteA,
      cipher: cipherA,
      tombstones: tombstonesA,
    ).synchronize(
      localItems: itemsA,
      replaceLocal: (items) async => itemsA = items,
    );
    expect(server.entities.single.encryptedPayload,
        isNot(contains('Windows note')));

    final download = await MemorySyncEngine(
      remote: remoteB,
      cipher: cipherB,
      tombstones: tombstonesB,
    ).synchronize(
      localItems: itemsB,
      replaceLocal: (items) async => itemsB = items,
    );
    expect(download.downloaded, 1);
    expect(itemsB.single.title, 'Windows note');

    itemsB = [
      itemsB.single.copyWith(
        title: 'Android edit',
        updatedAt: createdAt.add(const Duration(minutes: 1)),
      ),
    ];
    await MemorySyncEngine(
      remote: remoteB,
      cipher: cipherB,
      tombstones: tombstonesB,
    ).synchronize(
      localItems: itemsB,
      replaceLocal: (items) async => itemsB = items,
    );
    await MemorySyncEngine(
      remote: remoteA,
      cipher: cipherA,
      tombstones: tombstonesA,
    ).synchronize(
      localItems: itemsA,
      replaceLocal: (items) async => itemsA = items,
    );
    expect(itemsA.single.title, 'Android edit');

    final deletedAt = createdAt.add(const Duration(minutes: 2));
    itemsA = [];
    await tombstonesA.markDeleted('user', 'shared', deletedAt);
    await MemorySyncEngine(
      remote: remoteA,
      cipher: cipherA,
      tombstones: tombstonesA,
    ).synchronize(
      localItems: itemsA,
      replaceLocal: (items) async => itemsA = items,
    );
    final deletion = await MemorySyncEngine(
      remote: remoteB,
      cipher: cipherB,
      tombstones: tombstonesB,
    ).synchronize(
      localItems: itemsB,
      replaceLocal: (items) async => itemsB = items,
    );
    expect(deletion.deleted, 1);
    expect(itemsB, isEmpty);
  });
}

MemoryItem _item(String id, String title, DateTime date) => MemoryItem(
      id: id,
      type: MemoryType.note,
      title: title,
      memoryDate: date,
      createdAt: date,
      updatedAt: date,
    );

class _SyncServer {
  final entitiesById = <String, SyncRemoteEntity>{};
  final changes = StreamController<void>.broadcast();
  int revision = 0;

  List<SyncRemoteEntity> get entities => entitiesById.values.toList();
}

class _FakeRemoteStore implements SyncRemoteStore {
  _FakeRemoteStore(this.server);

  final _SyncServer server;

  @override
  String? get currentUserEmail => 'test@example.com';

  @override
  String? get currentUserId => 'user';

  @override
  Future<void> applyEntities(List<SyncRemoteEntity> entities) async {
    for (final incoming in entities) {
      final previous = server.entitiesById[incoming.entityId];
      if (previous != null && previous.updatedAt.isAfter(incoming.updatedAt)) {
        continue;
      }
      server.revision++;
      server.entitiesById[incoming.entityId] = SyncRemoteEntity(
        kind: incoming.kind,
        entityId: incoming.entityId,
        encryptedPayload: incoming.encryptedPayload,
        updatedAt: incoming.updatedAt,
        deletedAt: incoming.deletedAt,
        revision: server.revision,
      );
    }
    server.changes.add(null);
  }

  @override
  Future<void> createVaultProfile(SyncVaultProfile profile) async {}

  @override
  Future<List<SyncRemoteEntity>> fetchEntities() async => server.entities;

  @override
  Future<SyncVaultProfile?> fetchVaultProfile() async => null;

  @override
  Future<void> signIn(String email, String password) async {}

  @override
  Future<bool> signInWithGoogle() async => true;

  @override
  Future<void> signOut() async {}

  @override
  Future<SyncAuthResult> signUp(String email, String password) async {
    return const SyncAuthResult(hasSession: true);
  }

  @override
  Future<void> resendSignupConfirmation(String email) async {}

  @override
  Stream<void> watchAuthenticatedSession() => const Stream.empty();

  @override
  Stream<void> watchChanges() => server.changes.stream;
}

class _MemoryTombstoneStore extends SyncTombstoneStore {
  final values = <String, DateTime>{};

  @override
  Future<Map<String, DateTime>> read(
    String userId, {
    SyncEntityKind kind = SyncEntityKind.memoryItem,
  }) async =>
      {...values};

  @override
  Future<void> write(
    String userId,
    Map<String, DateTime> next, {
    SyncEntityKind kind = SyncEntityKind.memoryItem,
  }) async {
    values
      ..clear()
      ..addAll(next);
  }

  @override
  Future<void> markDeleted(
    String userId,
    String id,
    DateTime deletedAt, {
    SyncEntityKind kind = SyncEntityKind.memoryItem,
  }) async {
    values[id] = deletedAt;
  }
}
