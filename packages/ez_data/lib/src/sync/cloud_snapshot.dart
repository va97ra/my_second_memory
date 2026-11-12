import 'package:ez_domain/ez_domain.dart';

import 'sync_remote_store.dart';

/// Копия облачных строк пользователя в памяти и курсор по ревизии.
///
/// Слияние считает облачный список полным: чего в нём нет, того нет в облаке.
/// Поэтому прогон не может читать одно «что изменилось» — он дочитывает
/// новые строки, накладывает их на эту копию и отдаёт слиянию её целиком.
///
/// Копия — правда об облаке, а не о том, что успело слиться на устройстве.
/// Курсор двигается сразу после чтения: если прогон потом сорвался, следующий
/// найдёт ту же облачную правку здесь, вместе со слепком, и сольёт её.
///
/// Живёт, пока жив процесс и вход в аккаунт: при запуске, при входе в другой
/// аккаунт и при смене ключа хранилища облако читается заново целиком.
class CloudSnapshot {
  String? _userId;
  int _revision = 0;
  final _rows = <(SyncEntityKind, String), SyncRemoteEntity>{};

  /// Строки, которые отправило это устройство и о которых облако ещё не
  /// сообщило: сообщение о такой строке — эхо, а не новость.
  final _sent = <(SyncEntityKind, String, int)>{};

  /// Ссылки на вложения, сверенные с облаком до конца: всё доехало и ничего
  /// не потеряно. Пока набор тот же, бакет листать незачем.
  Set<String>? _settledMedia;

  /// Дочитывает облако с последней ревизии и возвращает его целиком.
  Future<List<SyncRemoteEntity>> refresh(SyncRemoteStore remote) async {
    final userId = remote.currentUserId;
    if (userId != _userId) {
      clear();
      _userId = userId;
    }
    for (final row in await remote.fetchEntities(afterRevision: _revision)) {
      final key = (row.kind, row.entityId);
      final known = _rows[key];
      if (known == null || row.revision >= known.revision) _rows[key] = row;
      if (row.revision > _revision) _revision = row.revision;
      // Своя строка уже прочитана: если эхо о ней придёт позже, оно
      // запустит лишний пустой прогон, но память не копится.
      _sent.remove(_sentKey(row));
    }
    return [..._rows.values];
  }

  /// Запоминает отправленное этим устройством.
  void recordSent(Iterable<SyncRemoteEntity> changes) =>
      _sent.addAll(changes.map(_sentKey));

  /// Сообщение облака о строке, которую отправило само это устройство.
  /// Каждое эхо узнаётся один раз.
  bool isOwnEcho(SyncRemoteEntity? change) =>
      change != null && _sent.remove(_sentKey(change));

  /// Сверены ли вложения для этого набора ссылок.
  bool mediaSettled(Set<String> references) {
    final settled = _settledMedia;
    return settled != null &&
        settled.length == references.length &&
        settled.containsAll(references);
  }

  /// Запоминает набор ссылок, сверенный до конца.
  void settleMedia(Set<String> references) => _settledMedia = {...references};

  static (SyncEntityKind, String, int) _sentKey(SyncRemoteEntity row) =>
      (row.kind, row.entityId, row.updatedAt.microsecondsSinceEpoch);

  /// Забывает облако: следующий прогон прочитает его целиком.
  void clear() {
    _userId = null;
    _revision = 0;
    _rows.clear();
    _sent.clear();
    _settledMedia = null;
  }
}
