import 'package:ez_domain/ez_domain.dart';

abstract interface class SyncRemoteStore {
  String? get currentUserId;
  String? get currentUserEmail;

  Future<SyncAuthResult> signUp(String email, String password);
  Future<void> resendSignupConfirmation(String email);
  Future<void> signIn(String email, String password);
  Future<bool> signInWithGoogle();
  Future<void> signOut();
  Stream<void> watchAuthenticatedSession();

  Future<SyncVaultProfile?> fetchVaultProfile();
  Future<void> createVaultProfile(SyncVaultProfile profile);

  Future<List<SyncRemoteEntity>> fetchEntities();
  Future<void> applyEntities(List<SyncRemoteEntity> entities);
  Stream<void> watchChanges();
}
