import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/local_storage_scope_provider.dart';
import '../../security/security.dart';
import '../../sync/sync.dart';

final toolDataRepositoryProvider = Provider<ToolDataRepository>((ref) {
  final session = ref.watch(securitySessionProvider);
  final storage = ref.watch(localStorageScopeProvider);
  final plainRepository = storage.toolDataRepository;
  if (session.hasPin && session.cipher != null) {
    return EncryptedToolDataRepository(
      store: EncryptedJsonStore(cipher: session.cipher!),
      plainRepository: plainRepository,
      backend: storage.secureEntityBackend,
    );
  }
  return plainRepository;
});

final toolDataControllerProvider =
    StateNotifierProvider<ToolDataController, AsyncValue<ToolDataSnapshot>>(
        (ref) {
  return ToolDataController(
    ref.watch(toolDataRepositoryProvider),
    ref.watch(syncMutationObserverProvider),
  );
});

class ToolDataController extends StateNotifier<AsyncValue<ToolDataSnapshot>> {
  ToolDataController(this._repository, [this._sync])
      : super(const AsyncValue.loading()) {
    _loadFuture = _load();
  }

  final ToolDataRepository _repository;
  final SyncMutationObserver? _sync;
  late final Future<void> _loadFuture;

  Future<void> load() => _loadFuture;

  /// То, что лежит сейчас. Пока загрузка не кончилась — пусто, а не null:
  /// инструменты обязаны открываться и без сохранённых расчётов.
  ToolDataSnapshot get snapshot =>
      state.valueOrNull ?? const ToolDataSnapshot();

  Future<void> _load() async {
    state = await AsyncValue.guard(_repository.load);
  }

  Future<void> saveCalculation(SavedToolCalculation calculation) async {
    await _loadFuture;
    final current = snapshot;
    await _save(ToolDataSnapshot(
      calculations: [
        calculation,
        for (final item in current.calculations)
          if (item.id != calculation.id) item,
      ],
      bookmarks: current.bookmarks,
      learning: current.learning,
    ));
    _sync?.toolCalculationsChanged();
  }

  Future<void> deleteCalculation(String id) async {
    await _loadFuture;
    final current = snapshot;
    final deletedAt = DateTime.now();
    await _save(ToolDataSnapshot(
      calculations: [
        for (final item in current.calculations)
          if (item.id != id) item,
      ],
      bookmarks: current.bookmarks,
      learning: current.learning,
    ));
    await _sync?.toolCalculationDeleted(id, deletedAt);
  }

  Future<void> renameCalculation(String id, String name) async {
    await _loadFuture;
    final current = snapshot;
    final now = DateTime.now();
    await _save(ToolDataSnapshot(
      calculations: [
        for (final item in current.calculations)
          if (item.id == id)
            item.copyWith(name: name.trim(), updatedAt: now)
          else
            item,
      ],
      bookmarks: current.bookmarks,
      learning: current.learning,
    ));
    _sync?.toolCalculationsChanged();
  }

  Future<void> saveBookmark({
    required String entryId,
    required String note,
  }) async {
    await _loadFuture;
    final current = snapshot;
    final bookmark = ReferenceBookmark(
      entryId: entryId,
      note: note.trim(),
      updatedAt: DateTime.now(),
    );
    await _save(ToolDataSnapshot(
      calculations: current.calculations,
      bookmarks: [
        bookmark,
        for (final item in current.bookmarks)
          if (item.entryId != entryId) item,
      ],
      learning: current.learning,
    ));
    _sync?.toolBookmarksChanged();
  }

  Future<void> deleteBookmark(String entryId) async {
    await _loadFuture;
    final current = snapshot;
    final deletedAt = DateTime.now();
    await _save(ToolDataSnapshot(
      calculations: current.calculations,
      bookmarks: [
        for (final item in current.bookmarks)
          if (item.entryId != entryId) item,
      ],
    ));
    await _sync?.toolBookmarkDeleted(entryId, deletedAt);
  }

  /// Замена расчётов приехавшим. Наблюдателю об этом не сообщают: правка
  /// пришла от него самого, и обратный вызов запустил бы прогон по кругу.
  Future<void> replaceCalculationsFromSync(
    List<SavedToolCalculation> calculations, {
    required List<SavedToolCalculation> baseline,
  }) async {
    await _loadFuture;
    final current = snapshot;
    await _save(ToolDataSnapshot(
      calculations: _newestFirst(
        mergeSyncedEntities(
          incoming: calculations,
          current: current.calculations,
          baseline: baseline,
          idOf: (item) => item.id,
          updatedAtOf: (item) => item.updatedAt,
        ),
        (item) => item.updatedAt,
      ),
      bookmarks: current.bookmarks,
      learning: current.learning,
    ));
  }

  Future<void> markTopicPassed(String topicId) async {
    await _loadFuture;
    final current = snapshot;
    if (current.learning.any((item) => item.topicId == topicId)) return;
    await _save(ToolDataSnapshot(
      calculations: current.calculations,
      bookmarks: current.bookmarks,
      learning: [
        LearningRecord(topicId: topicId, updatedAt: DateTime.now()),
        ...current.learning,
      ],
    ));
    _sync?.learningRecordsChanged();
  }

  Future<void> resetLearning() async {
    await _loadFuture;
    final current = snapshot;
    final deletedAt = DateTime.now();
    final removed = [for (final item in current.learning) item.topicId];
    await _save(ToolDataSnapshot(
      calculations: current.calculations,
      bookmarks: current.bookmarks,
    ));
    for (final topicId in removed) {
      await _sync?.learningRecordDeleted(topicId, deletedAt);
    }
  }

  Future<void> replaceLearningFromSync(
    List<LearningRecord> records, {
    required List<LearningRecord> baseline,
  }) async {
    await _loadFuture;
    final current = snapshot;
    await _save(ToolDataSnapshot(
      calculations: current.calculations,
      bookmarks: current.bookmarks,
      learning: _newestFirst(
        mergeSyncedEntities(
          incoming: records,
          current: current.learning,
          baseline: baseline,
          idOf: (item) => item.topicId,
          updatedAtOf: (item) => item.updatedAt,
        ),
        (item) => item.updatedAt,
      ),
    ));
  }

  Future<void> replaceBookmarksFromSync(
    List<ReferenceBookmark> bookmarks, {
    required List<ReferenceBookmark> baseline,
  }) async {
    await _loadFuture;
    final current = snapshot;
    await _save(ToolDataSnapshot(
      calculations: current.calculations,
      bookmarks: _newestFirst(
        mergeSyncedEntities(
          incoming: bookmarks,
          current: current.bookmarks,
          baseline: baseline,
          idOf: (item) => item.entryId,
          updatedAtOf: (item) => item.updatedAt,
        ),
        (item) => item.updatedAt,
      ),
      learning: current.learning,
    ));
  }

  Future<void> _save(ToolDataSnapshot next) async {
    final previous = state;
    state = AsyncValue.data(next);
    try {
      await _repository.replaceAll(next);
    } catch (error, stackTrace) {
      state = previous;
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

/// Списки инструментов показываются свежим сверху. Ручная правка кладёт новое
/// в начало сама; после слияния порядок восстанавливают по времени, иначе
/// приехавшее с другого устройства встаёт посреди списка.
List<T> _newestFirst<T>(List<T> items, DateTime Function(T) updatedAtOf) {
  final sorted = [...items]
    ..sort((first, second) => updatedAtOf(second).compareTo(updatedAtOf(first)));
  return List<T>.unmodifiable(sorted);
}
