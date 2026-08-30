import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ez_domain/ez_domain.dart';
import 'package:ez_data/ez_data.dart';

class RecurrenceExceptionController
    extends StateNotifier<List<RecurrenceOccurrenceException>> {
  RecurrenceExceptionController(this._repository, [this._sync])
      : super(const []) {
    _loadFuture = _load();
  }

  final RecurrenceExceptionRepository _repository;
  final SyncMutationObserver? _sync;
  late final Future<void> _loadFuture;

  Future<void> load() => _loadFuture;

  /// Отметки, лежащие в хранилище прямо сейчас.
  List<RecurrenceOccurrenceException> get exceptions => state;


  Future<void> _load() async => state = await _repository.loadAll();

  Future<void> upsert(RecurrenceOccurrenceException exception) async {
    await _loadFuture;
    await _repository.upsert(exception);
    state = _replace(exception);
    _sync?.recurrenceExceptionsChanged();
  }

  Future<void> upsertAll(
    List<RecurrenceOccurrenceException> exceptions,
  ) async {
    if (exceptions.isEmpty) return;
    await _loadFuture;
    await _repository.upsertAll(exceptions);
    final replacements = {for (final item in exceptions) item.id: item};
    state = [
      for (final item in state) replacements.remove(item.id) ?? item,
      ...replacements.values,
    ];
    _sync?.recurrenceExceptionsChanged();
  }

  Future<void> skip(String seriesId, DateTime occurrenceDate) async {
    await _loadFuture;
    final exception = await _repository.skip(seriesId, occurrenceDate);
    state = _replace(exception);
    _sync?.recurrenceExceptionsChanged();
  }

  Future<void> delete(String seriesId, DateTime occurrenceDate) async {
    await _loadFuture;
    final id = recurrenceExceptionId(seriesId, occurrenceDate);
    final deletedAt = DateTime.now();
    // Persist the cloud tombstone before the local delete so an interruption
    // cannot resurrect the exception on the next synchronization.
    await _sync?.recurrenceExceptionDeleted(id, deletedAt);
    await _repository.delete(seriesId, occurrenceDate);
    state = [
      for (final item in state)
        if (item.id != id) item
    ];
  }

  Future<void> deleteSeries(String seriesId) async {
    await _loadFuture;
    final deletedIds = [
      for (final item in state)
        if (item.seriesId == seriesId) item.id,
    ];
    final deletedAt = DateTime.now();
    for (final id in deletedIds) {
      await _sync?.recurrenceExceptionDeleted(id, deletedAt);
    }
    await _repository.deleteSeries(seriesId);
    state = [
      for (final item in state)
        if (item.seriesId != seriesId) item,
    ];
  }

  Future<void> replaceAll(
    List<RecurrenceOccurrenceException> exceptions,
  ) async {
    await _loadFuture;
    await _repository.replaceAll(exceptions);
    state = exceptions;
  }

  Future<void> replaceAllFromSync(
    List<RecurrenceOccurrenceException> exceptions, {
    required List<RecurrenceOccurrenceException> baseline,
  }) async {
    await _loadFuture;
    final merged = mergeSyncedEntities(
      incoming: exceptions,
      current: state,
      baseline: baseline,
      idOf: (item) => item.id,
      updatedAtOf: (item) => item.updatedAt,
    );
    await _repository.replaceAll(merged);
    state = merged;
  }

  List<RecurrenceOccurrenceException> _replace(
    RecurrenceOccurrenceException value,
  ) =>
      [
        for (final item in state)
          if (item.id == value.id) value else item,
        if (!state.any((item) => item.id == value.id)) value,
      ];
}
