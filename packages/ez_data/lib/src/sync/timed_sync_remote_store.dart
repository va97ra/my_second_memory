import 'dart:typed_data';

import 'package:ez_domain/ez_domain.dart';

import 'sync_remote_store.dart';

/// Bounds each network operation, not the synchronization pipeline. A late
/// response cannot resume the caller and overwrite data after a retry.
class TimedSyncRemoteStore implements SyncRemoteStore {
  const TimedSyncRemoteStore(
    this.inner, {
    this.requestTimeout = const Duration(seconds: 30),
    this.mediaTimeout = const Duration(minutes: 2),
  });

  final SyncRemoteStore inner;
  final Duration requestTimeout;
  final Duration mediaTimeout;

  @override
  String? get currentUserId => inner.currentUserId;
  @override
  String? get currentUserEmail => inner.currentUserEmail;
  @override
  Stream<void> watchAuthenticatedSession() => inner.watchAuthenticatedSession();
  @override
  Stream<void> watchChanges() => inner.watchChanges();
  @override
  Future<bool> signInWithGoogle() =>
      inner.signInWithGoogle().timeout(requestTimeout);
  @override
  Future<void> signOut() => inner.signOut().timeout(requestTimeout);
  @override
  Future<SyncVaultProfile?> fetchVaultProfile() =>
      inner.fetchVaultProfile().timeout(requestTimeout);
  @override
  Future<void> createVaultProfile(SyncVaultProfile profile) =>
      inner.createVaultProfile(profile).timeout(requestTimeout);
  @override
  Future<List<SyncRemoteEntity>> fetchEntities() =>
      inner.fetchEntities().timeout(requestTimeout);
  @override
  Future<void> applyEntities(List<SyncRemoteEntity> entities) =>
      inner.applyEntities(entities).timeout(requestTimeout);
  @override
  Future<Set<String>> listMediaNames() =>
      inner.listMediaNames().timeout(requestTimeout);
  @override
  Future<void> uploadMedia(String name, Uint8List bytes) =>
      inner.uploadMedia(name, bytes).timeout(mediaTimeout);
  @override
  Future<Uint8List> downloadMedia(String name) =>
      inner.downloadMedia(name).timeout(mediaTimeout);
  @override
  Future<void> deleteMedia(Iterable<String> names) =>
      inner.deleteMedia(names).timeout(requestTimeout);
}
