import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';

/// Уборка файлов, на которые больше никто не ссылается.
///
/// Фото или голос удаляют не тогда, когда их убрали из записи, а тогда, когда
/// на них не осталось ни одной ссылки: тот же файл может лежать в копии
/// записи, в шаблоне серии или в правке отдельной даты. Кто чем владеет,
/// решает `mediaReferencesOf`, поэтому кандидатов можно называть щедро —
/// удалится только ничьё.
class MediaCleanup {
  const MediaCleanup(this._storage, {required Set<String>? Function() owned})
      : _owned = owned;

  final MediaStorage? _storage;

  /// Ссылки всех данных прямо сейчас, или null, если данные ещё не
  /// загружены. Пока неизвестно, что чьё, не удаляется ничего: лишний файл
  /// на диске — меньшее зло, чем стёртое фото.
  final Set<String>? Function() _owned;

  /// Файлы, пропавшие из записи при её правке.
  Future<void> afterUpdate({
    required MemoryItem previous,
    required MemoryItem current,
  }) =>
      release(
        previous.mediaReferences.toSet()..removeAll(current.mediaReferences),
      );

  /// Удаляет те из [references], которыми больше никто не владеет.
  Future<void> release(Iterable<String> references) async {
    final storage = _storage;
    if (storage == null || references.isEmpty) return;
    final owned = _owned();
    if (owned == null) return;
    try {
      await storage.deleteOwnedFiles(references, usedPaths: owned);
    } catch (_) {
      // Файл останется лишним на диске; данные человека от этого не страдают.
    }
  }
}
