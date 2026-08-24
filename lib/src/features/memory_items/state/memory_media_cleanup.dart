import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';

/// Уборка файлов, на которые больше никто не ссылается.
///
/// Фотографию или голос удаляют не тогда, когда их убрали из записи, а тогда,
/// когда их не осталось ни в одной: один и тот же файл может лежать сразу в
/// нескольких записях после дублирования.
class MemoryMediaCleanup {
  const MemoryMediaCleanup(this._storage);

  final MediaStorage? _storage;

  /// Файлы, пропавшие из записи при её правке.
  Future<void> afterUpdate({
    required MemoryItem previous,
    required MemoryItem current,
    required List<MemoryItem> allItems,
  }) {
    final removed = mediaPathsOf(previous)..removeAll(mediaPathsOf(current));
    return deleteUnused(removed, allItems: allItems);
  }

  Future<void> deleteUnused(
    Iterable<String> paths, {
    required List<MemoryItem> allItems,
  }) async {
    try {
      await _storage?.deleteOwnedFiles(
        paths,
        usedPaths: {for (final item in allItems) ...mediaPathsOf(item)},
      );
    } catch (_) {
      // Следующий проход уборки повторит попытку.
    }
  }
}

/// Все файлы, на которые ссылается запись.
Set<String> mediaPathsOf(MemoryItem item) => {
      ...item.imagePaths,
      if (item.audioPath != null) item.audioPath!,
    };
