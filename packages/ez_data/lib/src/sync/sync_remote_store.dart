import 'package:ez_domain/ez_domain.dart';

abstract interface class SyncRemoteStore {
  String? get currentUserId;
  String? get currentUserEmail;

  Future<bool> signInWithGoogle();
  Future<void> signOut();
  Stream<void> watchAuthenticatedSession();

  Future<SyncVaultProfile?> fetchVaultProfile();
  Future<void> createVaultProfile(SyncVaultProfile profile);

  Future<List<SyncRemoteEntity>> fetchEntities();
  Future<void> applyEntities(List<SyncRemoteEntity> entities);
  Stream<void> watchChanges();
}
