import 'dart:typed_data';

import 'package:ez_domain/ez_domain.dart';

abstract interface class SyncRemoteStore {
  String? get currentUserId;
  String? get currentUserEmail;

  Future<bool> signInWithGoogle();
  Future<void> signOut();
  Stream<void> watchAuthenticatedSession();

  Future<SyncVaultProfile?> fetchVaultProfile();
  Future<void> createVaultProfile(SyncVaultProfile profile);

  /// Строки облака с ревизией больше [afterRevision], по возрастанию ревизии.
  /// С нулём — все строки пользователя.
  Future<List<SyncRemoteEntity>> fetchEntities({int afterRevision = 0});
  Future<void> applyEntities(List<SyncRemoteEntity> entities);

  /// Сообщения облака об изменённых строках: какая строка и в каком виде.
  /// Null — облако сообщило об изменении, но не сказало, о каком.
  Stream<SyncRemoteEntity?> watchChanges();

  /// Вложения лежат отдельно от записей: слепок записи — короткая строка, а
  /// снимок — мегабайты, и они не могут ездить в одной таблице, которую
  /// синхронизация вычитывает целиком на каждом прогоне.
  ///
  /// Имена — те же, что в записи, и в облаке они открыты: это `image_<время>`
  /// или `voice_<время>`, то есть тип вложения и момент съёмки. Не больше
  /// того, что уже открыто в `updated_at` у самой записи. Содержимое
  /// зашифровано ключом хранилища, как и слепки.
  Future<Set<String>> listMediaNames();
  Future<void> uploadMedia(String name, Uint8List bytes);
  Future<Uint8List> downloadMedia(String name);
  Future<void> deleteMedia(Iterable<String> names);
}
