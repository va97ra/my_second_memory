import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ez_domain/ez_domain.dart';
import 'sync_remote_store.dart';

class SupabaseSyncRemoteStore implements SyncRemoteStore {
  SupabaseSyncRemoteStore(this._client);

  static const oauthRedirectUrl = 'io.supabase.ezhednevnik://login-callback/';

  /// Приватный бакет вложений. Каждый пользователь видит только свою папку —
  /// это задаёт миграция `202609090001_sync_media.sql`.
  static const mediaBucket = 'sync-media';

  static const _mediaPageSize = 100;
  static const _entityPageSize = 1000;

  final SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  String? get currentUserEmail => _client.auth.currentUser?.email;

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

  /// Весь облачный слепок пользователя, по одной версии каждой сущности.
  ///
  /// Сервер молча режет ответ до своего Max rows (в Supabase по умолчанию
  /// 1000), поэтому таблица читается страницами. Страница начинается за
  /// последней прочитанной ревизией, а не со смещения: ревизия уникальна и
  /// растёт с каждой правкой, и строка, изменённая посреди чтения, не сдвигает
  /// остальные, а приезжает ещё раз в конце — остаётся её новая версия.
  /// Конец — пустая страница, а не короткая: так чтение не зависит от того,
  /// какой Max rows выставлен в проекте.
  @override
  Future<List<SyncRemoteEntity>> fetchEntities({int afterRevision = 0}) async {
    final userId = _requireUserId();
    final latest = <(SyncEntityKind, String), SyncRemoteEntity>{};
    var after = afterRevision;
    while (true) {
      final rows = await _client
          .from('sync_entities')
          .select(
            'entity_kind,entity_id,encrypted_payload,updated_at,deleted_at,revision',
          )
          .eq('user_id', userId)
          .gt('revision', after)
          // В postgrest по умолчанию порядок обратный. Курсор встаёт на
          // последнюю строку страницы, и только по возрастанию это самая
          // новая ревизия: иначе страница перечитывается заново.
          .order('revision', ascending: true)
          .limit(_entityPageSize);
      if (rows.isEmpty) break;
      for (final row in rows) {
        final entity =
            SyncRemoteEntity.fromJson(Map<String, Object?>.from(row));
        final key = (entity.kind, entity.entityId);
        latest.remove(key);
        latest[key] = entity;
        after = entity.revision;
      }
    }
    return [...latest.values];
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
  Stream<SyncRemoteEntity?> watchChanges() {
    final userId = currentUserId;
    if (userId == null) return const Stream.empty();
    late final RealtimeChannel channel;
    final controller = StreamController<SyncRemoteEntity?>(onCancel: () async {
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
          callback: (payload) => controller.add(_changedRow(payload)),
        )
        .subscribe();
    return controller.stream;
  }

  @override
  Future<Set<String>> listMediaNames() async {
    final userId = _requireUserId();
    final names = <String>{};
    // Список приходит страницами: у человека с многолетним дневником вложений
    // больше, чем отдаёт один запрос, и без страниц часть файлов выглядела бы
    // отсутствующей в облаке — то есть заливалась бы заново каждый прогон.
    for (var offset = 0;; offset += _mediaPageSize) {
      final page = await _client.storage.from(mediaBucket).list(
            path: userId,
            searchOptions: SearchOptions(
              limit: _mediaPageSize,
              offset: offset,
            ),
          );
      names.addAll(page.map((file) => file.name));
      if (page.length < _mediaPageSize) break;
    }
    return names;
  }

  @override
  Future<void> uploadMedia(String name, Uint8List bytes) async {
    await _client.storage.from(mediaBucket).uploadBinary(
          '${_requireUserId()}/$name',
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
  }

  @override
  Future<Uint8List> downloadMedia(String name) {
    return _client.storage.from(mediaBucket).download(
          '${_requireUserId()}/$name',
        );
  }

  @override
  Future<void> deleteMedia(Iterable<String> names) async {
    if (names.isEmpty) return;
    final userId = _requireUserId();
    await _client.storage.from(mediaBucket).remove([
      for (final name in names) '$userId/$name',
    ]);
  }

  /// Строка из сообщения облака. Таблица отдаёт строку целиком (`replica
  /// identity full`); если разобрать её не вышло, изменение всё равно есть —
  /// просто неизвестно какое.
  static SyncRemoteEntity? _changedRow(PostgresChangePayload payload) {
    final row = payload.newRecord;
    if (row.isEmpty) return null;
    try {
      return SyncRemoteEntity.fromJson(Map<String, Object?>.from(row));
    } on Object {
      return null;
    }
  }

  String _requireUserId() {
    final value = currentUserId;
    if (value == null) {
      throw StateError('Synchronization account is signed out');
    }
    return value;
  }
}
