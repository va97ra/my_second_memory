import 'dart:async';

import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_item.dart';
import 'package:ezhednevnik_v2/src/features/security/data/app_cipher.dart';
import 'package:ezhednevnik_v2/src/features/sync/data/sync_local_store.dart';
import 'package:ezhednevnik_v2/src/features/sync/data/sync_remote_store.dart';
import 'package:ezhednevnik_v2/src/features/sync/domain/sync_models.dart';
import 'package:ezhednevnik_v2/src/features/sync/state/sync_controller.dart';
import 'package:flutter_test/flutter_test.dart';

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
}

class _EmptyKeyStore extends SyncKeyStore {
  @override
  Future<AppCipher?> read(String userId) async => null;
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
  Future<void> signIn(String email, String password) async {}

  @override
  Future<void> signOut() async => _userId = null;

  @override
  Future<SyncAuthResult> signUp(String email, String password) async {
    return const SyncAuthResult(hasSession: false, emailConfirmation: true);
  }

  @override
  Stream<void> watchChanges() => const Stream.empty();
}
