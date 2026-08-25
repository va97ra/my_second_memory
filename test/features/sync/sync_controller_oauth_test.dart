import 'dart:async';

import 'package:ez_domain/ez_domain.dart';
import 'package:ez_data/ez_data.dart';
import 'package:ezhednevnik_v2/src/features/sync/state/sync_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Google OAuth callback advances a signed-out session to vault setup',
      () async {
    final remote = _OAuthRemoteStore();
    final controller = SyncController(
      remote: remote,
      keyStore: _EmptyKeyStore(),
      tombstones: const SyncTombstoneStore(),
      data: SyncDataSources(
        readMemoryItems: () async => <MemoryItem>[],
        replaceMemoryItems: (_) async {},
      ),
    );
    addTearDown(() {
      controller.dispose();
      remote.dispose();
    });

    await controller.load();
    expect(controller.state.status, SyncStatus.signedOut);

    expect(await controller.signInWithGoogle(), isTrue);
    expect(controller.state.status, SyncStatus.signedOut);

    remote.completeGoogleSignIn();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.status, SyncStatus.needsVault);
    expect(controller.state.email, 'test@example.com');
    expect(controller.state.vaultExists, isFalse);
  });

  test('encrypted records wait for PIN unlock before synchronization',
      () async {
    SharedPreferences.setMockInitialValues({});
    var localDataAvailable = false;
    final remote = _ConnectedRemoteStore();
    final controller = SyncController(
      remote: remote,
      keyStore: _ConnectedKeyStore(),
      tombstones: const SyncTombstoneStore(),
      canAccessLocalData: () => localDataAvailable,
      data: SyncDataSources(
        readMemoryItems: () async => <MemoryItem>[],
        replaceMemoryItems: (_) async {},
      ),
    );
    addTearDown(controller.dispose);

    await controller.load();
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(controller.state.status, SyncStatus.ready);
    expect(remote.fetchEntitiesCalls, 0);

    localDataAvailable = true;
    controller.localDataAvailabilityChanged(true);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(remote.fetchEntitiesCalls, 1);
    expect(controller.state.status, SyncStatus.ready);
  });

  test('deletion is recorded while the sync cipher is still loading', () async {
    final remote = _ConnectedRemoteStore();
    final tombstones = _RecordingTombstoneStore();
    final controller = SyncController(
      remote: remote,
      keyStore: _EmptyKeyStore(),
      tombstones: tombstones,
      data: SyncDataSources(
        readMemoryItems: () async => <MemoryItem>[],
        replaceMemoryItems: (_) async {},
      ),
    );
    addTearDown(() {
      controller.dispose();
      remote.dispose();
    });

    expect(controller.state.status, SyncStatus.loading);
    await controller.recordDeletion(
      SyncEntityKind.memoryItem,
      'deleted-during-startup',
      DateTime.utc(2026, 8, 22, 12),
    );

    expect(
      (await tombstones.read('google-user'))['deleted-during-startup'],
      DateTime.utc(2026, 8, 22, 12),
    );
  });

  test('sync requested during an active run performs a second run', () async {
    SharedPreferences.setMockInitialValues({});
    var localDataAvailable = false;
    final remote = _BlockingConnectedRemoteStore();
    final controller = SyncController(
      remote: remote,
      keyStore: _ConnectedKeyStore(),
      tombstones: const SyncTombstoneStore(),
      canAccessLocalData: () => localDataAvailable,
      data: SyncDataSources(
        readMemoryItems: () async => <MemoryItem>[],
        replaceMemoryItems: (_) async {},
      ),
    );
    addTearDown(() {
      controller.dispose();
      remote.dispose();
    });
    await controller.load();
    localDataAvailable = true;

    final firstRun = controller.syncNow();
    await remote.firstFetchStarted.future;
    final repeatedRequest = controller.syncNow();
    remote.releaseFirstFetch.complete();

    await remote.secondFetchStarted.future.timeout(const Duration(seconds: 2));
    await Future.wait([firstRun, repeatedRequest]);
    expect(remote.fetchEntitiesCalls, 2);
  });
}

class _EmptyKeyStore extends SyncKeyStore {
  @override
  Future<AppCipher?> read(String userId) async => null;
}

class _ConnectedKeyStore extends SyncKeyStore {
  @override
  Future<AppCipher?> read(String userId) async {
    return AppCipher.fromKeyBytes(List<int>.generate(32, (index) => index));
  }
}

class _ConnectedRemoteStore extends _OAuthRemoteStore {
  _ConnectedRemoteStore() {
    completeGoogleSignIn();
  }

  int fetchEntitiesCalls = 0;

  @override
  Future<List<SyncRemoteEntity>> fetchEntities() async {
    fetchEntitiesCalls++;
    return const [];
  }
}

class _BlockingConnectedRemoteStore extends _ConnectedRemoteStore {
  final firstFetchStarted = Completer<void>();
  final releaseFirstFetch = Completer<void>();
  final secondFetchStarted = Completer<void>();

  @override
  Future<List<SyncRemoteEntity>> fetchEntities() async {
    fetchEntitiesCalls++;
    if (fetchEntitiesCalls == 1) {
      firstFetchStarted.complete();
      await releaseFirstFetch.future;
    } else if (fetchEntitiesCalls == 2) {
      secondFetchStarted.complete();
    }
    return const [];
  }
}

class _RecordingTombstoneStore extends SyncTombstoneStore {
  final _values = <SyncEntityKind, Map<String, DateTime>>{};

  @override
  Future<Map<String, DateTime>> read(
    String userId, {
    SyncEntityKind kind = SyncEntityKind.memoryItem,
  }) async =>
      {...?_values[kind]};

  @override
  Future<void> write(
    String userId,
    Map<String, DateTime> values, {
    SyncEntityKind kind = SyncEntityKind.memoryItem,
  }) async {
    _values[kind] = {...values};
  }

  @override
  Future<void> markDeleted(
    String userId,
    String id,
    DateTime deletedAt, {
    SyncEntityKind kind = SyncEntityKind.memoryItem,
  }) async {
    (_values[kind] ??= {})[id] = deletedAt;
  }
}

class _OAuthRemoteStore implements SyncRemoteStore {
  final _authChanges = StreamController<void>.broadcast();
  String? _userId;
  @override
  String? get currentUserEmail => _userId == null ? null : 'test@example.com';

  @override
  String? get currentUserId => _userId;

  void completeGoogleSignIn() {
    _userId = 'google-user';
    _authChanges.add(null);
  }

  void dispose() => _authChanges.close();

  @override
  Future<bool> signInWithGoogle() async => true;

  @override
  Stream<void> watchAuthenticatedSession() => _authChanges.stream;

  @override
  Future<SyncVaultProfile?> fetchVaultProfile() async => null;

  @override
  Future<List<SyncRemoteEntity>> fetchEntities() async => const [];

  @override
  Future<void> applyEntities(List<SyncRemoteEntity> entities) async {}

  @override
  Future<void> createVaultProfile(SyncVaultProfile profile) async {}

  @override
  Future<void> signOut() async => _userId = null;

  @override
  Stream<void> watchChanges() => const Stream.empty();
}
