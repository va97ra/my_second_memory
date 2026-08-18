import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../sync/domain/sync_mutation_observer.dart';
import '../data/recurrence_exception_repository.dart';
import '../domain/recurrence_occurrence_exception.dart';

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
    await _repository.delete(seriesId, occurrenceDate);
    state = [
      for (final item in state)
        if (item.id != id) item
    ];
    await _sync?.recurrenceExceptionDeleted(id, DateTime.now());
  }

  Future<void> deleteSeries(String seriesId) async {
    await _loadFuture;
    final deletedIds = [
      for (final item in state)
        if (item.seriesId == seriesId) item.id,
    ];
    await _repository.deleteSeries(seriesId);
    state = [
      for (final item in state)
        if (item.seriesId != seriesId) item,
    ];
    final deletedAt = DateTime.now();
    for (final id in deletedIds) {
      await _sync?.recurrenceExceptionDeleted(id, deletedAt);
    }
  }

  Future<void> replaceAll(
    List<RecurrenceOccurrenceException> exceptions,
  ) async {
    await _loadFuture;
    await _repository.replaceAll(exceptions);
    state = exceptions;
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
