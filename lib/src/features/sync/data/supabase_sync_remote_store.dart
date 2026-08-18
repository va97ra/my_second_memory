import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/sync_models.dart';
import 'sync_remote_store.dart';

class SupabaseSyncRemoteStore implements SyncRemoteStore {
  SupabaseSyncRemoteStore(this._client);

  static const oauthRedirectUrl = 'io.supabase.ezhednevnik://login-callback/';

  final SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  String? get currentUserEmail => _client.auth.currentUser?.email;

  @override
  Future<SyncAuthResult> signUp(String email, String password) async {
    final response =
        await _client.auth.signUp(email: email, password: password);
    return SyncAuthResult(
      hasSession: response.session != null,
      emailConfirmation: response.session == null,
    );
  }

  @override
  Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<bool> signInWithGoogle() {
    return _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : oauthRedirectUrl,
      authScreenLaunchMode:
          kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
    );
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Stream<void> watchAuthenticatedSession() {
    return _client.auth.onAuthStateChange
        .where((state) => state.session != null)
        .map((_) {});
  }

  @override
  Future<SyncVaultProfile?> fetchVaultProfile() async {
    final userId = _requireUserId();
    final rows = await _client
        .from('sync_profiles')
        .select('key_salt,wrapped_key,key_verifier')
        .eq('user_id', userId)
        .limit(1);
    if (rows.isEmpty) return null;
    final row = Map<String, Object?>.from(rows.first);
    return SyncVaultProfile(
      salt: row['key_salt'] as String,
      wrappedKey: row['wrapped_key'] as String,
      keyVerifier: row['key_verifier'] as String,
    );
  }

  @override
  Future<void> createVaultProfile(SyncVaultProfile profile) async {
    await _client.from('sync_profiles').insert({
      'user_id': _requireUserId(),
      'key_salt': profile.salt,
      'wrapped_key': profile.wrappedKey,
      'key_verifier': profile.keyVerifier,
    });
  }

  @override
  Future<List<SyncRemoteEntity>> fetchEntities() async {
    final rows = await _client
        .from('sync_entities')
        .select(
          'entity_kind,entity_id,encrypted_payload,updated_at,deleted_at,revision',
        )
        .eq('user_id', _requireUserId())
        .order('revision');
    return [
      for (final row in rows)
        SyncRemoteEntity.fromJson(Map<String, Object?>.from(row)),
    ];
  }

  @override
  Future<void> applyEntities(List<SyncRemoteEntity> entities) async {
    if (entities.isEmpty) return;
    await _client.rpc(
      'apply_sync_changes',
      params: {
        'p_changes': [for (final entity in entities) entity.toRpcJson()],
      },
    );
  }

  @override
  Stream<void> watchChanges() {
    final userId = currentUserId;
    if (userId == null) return const Stream.empty();
    late final RealtimeChannel channel;
    final controller = StreamController<void>(onCancel: () async {
      await _client.removeChannel(channel);
    });
    channel = _client
        .channel('sync_entities:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'sync_entities',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) => controller.add(null),
        )
        .subscribe();
    return controller.stream;
  }

  String _requireUserId() {
    final value = currentUserId;
    if (value == null) {
      throw StateError('Synchronization account is signed out');
    }
    return value;
  }
}
