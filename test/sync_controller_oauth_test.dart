import 'dart:async';

import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_item.dart';
import 'package:ezhednevnik_v2/src/features/security/data/app_cipher.dart';
import 'package:ezhednevnik_v2/src/features/sync/data/sync_local_store.dart';
import 'package:ezhednevnik_v2/src/features/sync/data/sync_remote_store.dart';
import 'package:ezhednevnik_v2/src/features/sync/domain/sync_models.dart';
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
      readMemoryItems: () async => <MemoryItem>[],
      replaceMemoryItems: (_) async {},
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

  test('email confirmation can be resent without leaving confirmation screen',
      () async {
    final remote = _OAuthRemoteStore();
    final controller = SyncController(
      remote: remote,
      keyStore: _EmptyKeyStore(),
      tombstones: const SyncTombstoneStore(),
      readMemoryItems: () async => <MemoryItem>[],
      replaceMemoryItems: (_) async {},
    );
    addTearDown(() {
      controller.dispose();
      remote.dispose();
    });

    await controller.load();
    expect(await controller.register('test@example.com', 'password'), isFalse);
    expect(controller.state.status, SyncStatus.awaitingEmailConfirmation);

    expect(await controller.resendSignupConfirmation(), isTrue);
    expect(remote.resendConfirmationCalls, 1);
    expect(controller.state.status, SyncStatus.awaitingEmailConfirmation);
    expect(controller.state.confirmationResent, isTrue);
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
      readMemoryItems: () async => <MemoryItem>[],
      replaceMemoryItems: (_) async {},
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

class _OAuthRemoteStore implements SyncRemoteStore {
  final _authChanges = StreamController<void>.broadcast();
  String? _userId;
  int resendConfirmationCalls = 0;

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
  Future<void> signIn(String email, String password) async {}

  @override
  Future<void> signOut() async => _userId = null;

  @override
  Future<SyncAuthResult> signUp(String email, String password) async {
    return const SyncAuthResult(hasSession: false, emailConfirmation: true);
  }

  @override
  Future<void> resendSignupConfirmation(String email) async {
    resendConfirmationCalls++;
  }

  @override
  Stream<void> watchChanges() => const Stream.empty();
}
