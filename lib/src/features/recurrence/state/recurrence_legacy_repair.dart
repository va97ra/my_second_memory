import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';

import '../../memory_items/memory_items.dart';
import 'recurrence_exception_controller.dart';

/// То, что ремонту нужно от контроллера серий.
///
/// Интерфейс существует, чтобы связь была видна: ремонт читает и переписывает
/// то же состояние, что и обычные операции, и обязан ходить туда явно.
abstract interface class RecurrenceRepairHost {
  List<RecurrenceSeries> get series;

  void replaceSeries(List<RecurrenceSeries> value);

  RecurrenceSeries? findSeries(String id);

  DateTime sourceDateFor(MemoryItem item, [DateTime? fallback]);

  /// Снимает отдельную строку, которую повторяющаяся запись держала рядом с
  /// серией, сохраняя её медиа и напоминание.
  Future<void> retireOriginRow(RecurrenceSeries series);

  /// Помечает вхождение удалённым: отметка заменяется, а не удаляется, иначе
  /// облачный tombstone переживёт её и убьёт следующее удаление.
  Future<void> writeDeletionMarker(
    MemoryItem item,
    DateTime sourceDate, {
    DateTime? deletedAt,
  });

  /// Убирает переопределения того же вхождения, записанные под чужой датой.
  Future<void> deleteMiskeyedOverrides(MemoryItem item, DateTime sourceDate);
}

/// Ремонт данных, написанных прошлыми сборками.
///
/// Каждый проход приводит уцелевшее старое представление вхождения к
/// единственному нынешнему: правка живёт в исключении на исходную дату, а
/// строк у вхождений нет вовсе. Проходы идут при каждой загрузке, потому что
/// старые данные могут приехать по синхронизации с устройства, которое ещё не
/// обновилось.
///
/// Когда таких устройств не останется, проходы станут вечными no-op и класс
/// удаляется целиком — он для того и отделён.
class RecurrenceLegacyRepair {
  RecurrenceLegacyRepair({
    required RecurrenceRepairHost host,
    required RecurrenceRepository repository,
    required RecurrenceExceptionController exceptions,
    required MemoryItemsController memoryItems,
    SyncMutationObserver? sync,
  })  : _host = host,
        _repository = repository,
        _exceptions = exceptions,
        _memoryItems = memoryItems,
        _sync = sync;

  final RecurrenceRepairHost _host;
  final RecurrenceRepository _repository;
  final RecurrenceExceptionController _exceptions;
  final MemoryItemsController _memoryItems;
  final SyncMutationObserver? _sync;

  /// Полный набор проходов, выполняемый при загрузке.
  ///
  /// Порядок важен: сначала материализованные копии превращаются в
  /// исключения, затем применяются отметки удаления, и только потом строки
  /// сворачиваются в серии — после сворачивания читать уже нечего.
  Future<void> runOnLoad() async {
    await _migrateGeneratedCopies();
    await _applyMemoryDeletionTombstones();
    await _applySkippedOccurrenceDeletes();
    await _restoreOriginOverrides();
    await _refreshStaleTemplatesFromOrigins();
    await _foldOriginRowsIntoSeries();
  }

  /// Повторное согласование после синхронизации: удаление могло приехать с
  /// другого устройства уже после загрузки.
  Future<void> reconcileOriginOverrides() async {
    await _applyMemoryDeletionTombstones();
    await _applySkippedOccurrenceDeletes();
  }

  Future<void> _refreshStaleTemplatesFromOrigins() async {
    if (_host.series.isEmpty || _memoryItems.items.isEmpty) return;
    final itemsById = {
      for (final item in _memoryItems.items) item.id: item,
    };
    final repaired = <RecurrenceSeries>[];
    var latestTimestamp = DateTime.now();
    for (final series in _host.series) {
      final origin = itemsById[series.originItemId];
      final template = series.template;
      final hasOriginOverride = _exceptions.exceptions.any(
        (exception) =>
            exception.seriesId == series.id &&
            (dateKey(exception.occurrenceDate) == dateKey(series.startDate) ||
                exception.item?.id == series.originItemId),
      );
      if (origin == null ||
          hasOriginOverride ||
          origin.seriesId != series.id ||
          origin.id != template.id ||
          origin.isGeneratedOccurrence ||
          !origin.updatedAt.isAfter(template.updatedAt) ||
          !_looksLikeIncompleteInitialSave(series, origin)) {
        continue;
      }
      if (!latestTimestamp.isAfter(series.updatedAt)) {
        latestTimestamp = series.updatedAt.add(const Duration(microseconds: 1));
      }
      if (!latestTimestamp.isAfter(origin.updatedAt)) {
        latestTimestamp = origin.updatedAt.add(const Duration(microseconds: 1));
      }
      repaired.add(
        series.copyWith(
          template: origin.copyWith(
            seriesId: series.id,
            repeatRule: series.frequency.name,
            isGeneratedOccurrence: false,
          ),
          updatedAt: latestTimestamp,
        ),
      );
      latestTimestamp = latestTimestamp.add(const Duration(microseconds: 1));
    }
    if (repaired.isEmpty) return;
    await _repository.upsertAll(repaired);
    final replacements = {for (final series in repaired) series.id: series};
    _host.replaceSeries([
      for (final series in _host.series) replacements[series.id] ?? series,
    ]);
    _sync?.recurrenceSeriesChanged();
  }

  bool _looksLikeIncompleteInitialSave(
    RecurrenceSeries series,
    MemoryItem origin,
  ) {
    final editDelay = origin.updatedAt.difference(series.createdAt);
    final template = series.template;
    if (template.updatedAt != series.createdAt ||
        origin.type != template.type ||
        origin.createdAt != template.createdAt ||
        dateKey(origin.memoryDate) != dateKey(template.memoryDate) ||
        dateKey(template.memoryDate) != dateKey(series.startDate) ||
        editDelay.isNegative ||
        editDelay > const Duration(minutes: 2)) {
      return false;
    }
    // The legacy autosave bug captured either a partially typed line or the
    // item before its type-specific metadata was filled. Restrict the repair
    // to those completion patterns so an arbitrary occurrence override is not
    // promoted to the whole series.
    final expandedText = _expandedDuringInitialSave(
          template.title,
          origin.title,
        ) ||
        _expandedDuringInitialSave(template.body, origin.body);
    final filledMissingMetadata = (template.amountMinor == null &&
            origin.amountMinor != null) ||
        (template.paymentCategory == null && origin.paymentCategory != null) ||
        (template.birthYear == null && origin.birthYear != null);
    return expandedText || filledMissingMetadata;
  }

  bool _expandedDuringInitialSave(String before, String after) {
    final partial = before.trim();
    final completed = after.trim();
    if (partial.isEmpty || partial == completed || completed.isEmpty) {
      return false;
    }
    // The affected legacy save captured the tail of a name (for example,
    // "Анаста" before a surname was prepended). A normal append such as
    // "Купить" -> "Купить молоко" must remain scoped to one occurrence.
    final wordCharacter = RegExp(r'[A-Za-zА-Яа-яЁё0-9]');
    var start = completed.indexOf(partial);
    while (start > 0) {
      final end = start + partial.length;
      final hasLeftBoundary =
          !wordCharacter.hasMatch(completed.substring(start - 1, start));
      final continuesWord = end < completed.length &&
          wordCharacter.hasMatch(completed.substring(end, end + 1));
      if (hasLeftBoundary && continuesWord) return true;
      start = completed.indexOf(partial, start + 1);
    }
    return false;
  }

  Future<void> _restoreOriginOverrides() async {
    if (_host.series.isEmpty || _exceptions.exceptions.isEmpty) return;
    final memoryDeletions =
        await _sync?.memoryDeletions() ?? const <String, DateTime>{};
    final itemsById = {
      for (final item in _memoryItems.items) item.id: item,
    };
    for (final series in _host.series) {
      final canonicalId = recurrenceExceptionId(series.id, series.startDate);
      final related = [
        for (final exception in _exceptions.exceptions)
          if (exception.seriesId == series.id &&
              (exception.id == canonicalId ||
                  exception.item?.id == series.originItemId))
            exception,
      ];
      if (related.isEmpty) continue;
      var winner = related.first;
      for (final exception in related.skip(1)) {
        if (exception.updatedAt.isAfter(winner.updatedAt)) {
          winner = exception;
        }
      }
      if (winner.isSkipped || winner.item == null) {
        for (final exception in related) {
          if (exception.id != canonicalId) {
            await _exceptions.delete(series.id, exception.occurrenceDate);
          }
        }
        continue;
      }
      final item = winner.item!;
      if (item.id != series.originItemId || item.isGeneratedOccurrence) {
        continue;
      }
      // A recurrence marker can recover a partially written edit. A newer
      // marker is also allowed to recreate an intentionally re-added item,
      // while an equal/newer deletion remains authoritative.
      final deletedAt = memoryDeletions[item.id];
      if (deletedAt != null &&
          !winner.updatedAt.isAfter(deletedAt) &&
          !item.updatedAt.isAfter(deletedAt)) {
        continue;
      }
      if (winner.id != canonicalId) {
        RecurrenceOccurrenceException? existingCanonical;
        for (final exception in related) {
          if (exception.id == canonicalId) {
            existingCanonical = exception;
            break;
          }
        }
        winner = RecurrenceOccurrenceException(
          id: canonicalId,
          seriesId: series.id,
          occurrenceDate: dateOnly(series.startDate),
          kind: RecurrenceOccurrenceExceptionKind.modified,
          item: item,
          createdAt: existingCanonical?.createdAt ?? winner.createdAt,
          updatedAt: winner.updatedAt,
        );
        // Write the canonical copy first. A retry may briefly see two markers,
        // but an interruption can never discard the newest user edit.
        await _exceptions.upsert(winner);
      }
      await _host.deleteMiskeyedOverrides(item, dateOnly(series.startDate));
      final persisted = itemsById[series.originItemId];
      if (persisted != null && !item.updatedAt.isAfter(persisted.updatedAt)) {
        continue;
      }
      final restored = item.copyWith(
        seriesId: series.id,
        repeatRule: series.frequency.name,
        isGeneratedOccurrence: false,
        updatedAt: winner.updatedAt.isAfter(item.updatedAt)
            ? winner.updatedAt
            : item.updatedAt,
      );
      if (persisted == null) {
        await _memoryItems.add(restored);
      } else {
        await _memoryItems.update(restored);
      }
      itemsById[item.id] = restored;
    }
  }

  /// Folds the standalone row a recurring record used to keep into its series.
  /// Whatever that row still says is kept as an override of the first
  /// occurrence, never promoted to the template: an edit is only ever known to
  /// apply to the occurrence it was made on, and guessing wider once corrupted
  /// whole series.

  Future<void> _foldOriginRowsIntoSeries() async {
    if (_host.series.isEmpty || _memoryItems.items.isEmpty) return;
    final rowsById = {for (final item in _memoryItems.items) item.id: item};
    final overrides = <RecurrenceOccurrenceException>[];
    for (final series in _host.series) {
      final row = rowsById[series.originItemId];
      if (row == null || row.seriesId != series.id) continue;
      final startDate = dateOnly(series.startDate);
      final exceptionId = recurrenceExceptionId(series.id, startDate);
      final hasMarker =
          _exceptions.exceptions.any((exception) => exception.id == exceptionId);
      if (hasMarker) continue;
      if (isUntouchedGeneratedOccurrence(
        row,
        occurrenceFromSeries(series, startDate),
      )) {
        continue;
      }
      overrides.add(
        RecurrenceOccurrenceException(
          id: exceptionId,
          seriesId: series.id,
          occurrenceDate: startDate,
          kind: RecurrenceOccurrenceExceptionKind.modified,
          item: row.copyWith(
            seriesId: series.id,
            repeatRule: series.frequency.name,
            isGeneratedOccurrence: true,
          ),
          // The row is dropped below, which tombstones its id. This marker
          // takes its place, so it has to outlive that tombstone.
          survivesMemoryDeletion: true,
          createdAt: row.createdAt,
          updatedAt: row.updatedAt,
        ),
      );
    }
    // Write the overrides before dropping the rows they came from.
    await _exceptions.upsertAll(overrides);
    for (final series in _host.series) {
      await _host.retireOriginRow(series);
    }
  }

  Future<void> _applyMemoryDeletionTombstones() async {
    if (_sync == null) return;
    final memoryDeletions = await _sync.memoryDeletions();
    // A tombstone on the origin id only means its standalone row was
    // retired when the record became recurring. Deleting the first
    // occurrence writes an explicit skip marker like any other.
    if (_exceptions.exceptions.isEmpty) return;
    for (final exception in [..._exceptions.exceptions]) {
      final item = exception.item;
      if (item == null) continue;
      final deletedAt = memoryDeletions[item.id];
      if (deletedAt == null) continue;
      if (!exception.isSkipped && exception.survivesMemoryDeletion) continue;
      if (!exception.isSkipped &&
          (exception.updatedAt.isAfter(deletedAt) ||
              item.updatedAt.isAfter(deletedAt))) {
        continue;
      }
      final sourceDate = _host.sourceDateFor(item, exception.occurrenceDate);
      final canonicalId = recurrenceExceptionId(exception.seriesId, sourceDate);
      if (exception.id == canonicalId &&
          exception.isSkipped &&
          exception.item?.id == item.id &&
          !deletedAt.isAfter(exception.updatedAt)) {
        continue;
      }
      await _host.writeDeletionMarker(item, sourceDate, deletedAt: deletedAt);
      await _host.deleteMiskeyedOverrides(item, sourceDate);
    }
  }

  Future<void> _applySkippedOccurrenceDeletes() async {
    if (_exceptions.exceptions.isEmpty || _memoryItems.items.isEmpty) return;
    final memoryDeletions =
        await _sync?.memoryDeletions() ?? const <String, DateTime>{};
    final occurrenceIndex = RecurrenceOccurrenceIndex(
      series: _host.series,
      exceptions: _exceptions.exceptions,
    );
    for (final exception in [..._exceptions.exceptions]) {
      if (!exception.isSkipped) continue;
      for (final item in [..._memoryItems.items]) {
        if (item.seriesId != exception.seriesId ||
            dateKey(_host.sourceDateFor(item)) !=
                dateKey(exception.occurrenceDate)) {
          continue;
        }
        final deletedAt = memoryDeletions[item.id];
        final deletionWins =
            deletedAt != null && !item.updatedAt.isAfter(deletedAt);
        final explicitlyDeleted = exception.item?.id == item.id;
        final isUnmoved =
            dateKey(item.memoryDate) == dateKey(exception.occurrenceDate);
        if (!explicitlyDeleted && !isUnmoved && !deletionWins) continue;
        // A row materialized from the series only caches the projection, so
        // its launch timestamp must never outrank the deletion marker.
        final isCachedProjection = occurrenceIndex.isMaterializedProjection(
          item,
          exception.occurrenceDate,
        );
        if (!deletionWins &&
            !isCachedProjection &&
            item.updatedAt.isAfter(exception.updatedAt)) {
          continue;
        }
        await _memoryItems.delete(item.id);
      }
    }
  }

  Future<void> _migrateGeneratedCopies() async {
    final today = dateOnly(DateTime.now());
    final memoryDeletions =
        await _sync?.memoryDeletions() ?? const <String, DateTime>{};
    // Every materialized occurrence is legacy now, past ones included: an
    // edited one becomes its exception, an untouched one goes back to being a
    // plain projection.
    final legacy = [
      for (final item in _memoryItems.items)
        if (item.isGeneratedOccurrence) item,
    ];
    if (legacy.isEmpty) return;
    final migrated = <RecurrenceOccurrenceException>[];
    final migratedIds = <String>{};
    final existingExceptions = {
      for (final exception in _exceptions.exceptions) exception.id: exception,
    };
    for (final item in legacy) {
      final seriesId = item.seriesId;
      final series = seriesId == null ? null : _host.findSeries(seriesId);
      if (series != null) {
        final sourceDate = occurrenceDateFromId(series.id, item.id);
        if (sourceDate == null || !isOccurrenceDate(series, sourceDate)) {
          continue;
        }
        final expected = occurrenceFromSeries(series, sourceDate);
        final wasMoved = dateKey(sourceDate) != dateKey(item.memoryDate);
        final exceptionId = recurrenceExceptionId(series.id, sourceDate);
        final existing = existingExceptions[exceptionId];
        final deletedAt = memoryDeletions[item.id];
        final hasDeletionSkip = _exceptions.exceptions.any(
          (exception) =>
              exception.seriesId == series.id &&
              exception.isSkipped &&
              (exception.item?.id == item.id ||
                  (!wasMoved &&
                      dateKey(exception.occurrenceDate) ==
                          dateKey(sourceDate)) ||
                  (wasMoved &&
                      deletedAt != null &&
                      existing?.survivesMemoryDeletion != true &&
                      (dateKey(exception.occurrenceDate) ==
                              dateKey(sourceDate) ||
                          dateKey(exception.occurrenceDate) ==
                              dateKey(item.memoryDate)))),
        );
        final hasModifiedCopy = existing != null && !existing.isSkipped;
        final wasEdited = wasMoved || !isUntouchedGeneratedOccurrence(item, expected);
        if (!hasDeletionSkip && (hasModifiedCopy || wasEdited)) {
          final markerItem = existing != null &&
                  !item.updatedAt.isAfter(existing.updatedAt) &&
                  existing.item != null
              ? existing.item!
              : item;
          final markerUpdatedAt = existing != null &&
                  existing.updatedAt.isAfter(markerItem.updatedAt)
              ? existing.updatedAt
              : markerItem.updatedAt;
          migrated.add(
            RecurrenceOccurrenceException(
              id: exceptionId,
              seriesId: series.id,
              occurrenceDate: dateOnly(sourceDate),
              kind: RecurrenceOccurrenceExceptionKind.modified,
              item: markerItem,
              survivesMemoryDeletion: true,
              createdAt: existing?.createdAt ?? markerItem.updatedAt,
              updatedAt: markerUpdatedAt,
            ),
          );
        }
        migratedIds.add(item.id);
      }
    }
    if (migratedIds.isEmpty) return;
    // Persist user changes before deleting legacy copies. A retry can safely
    // deduplicate both representations, while the opposite order can lose an
    // edited occurrence if the exception write fails.
    await _exceptions.upsertAll(migrated);
    await _memoryItems.removeMigratedRecurrenceCopies(migratedIds);
    final reset = [
      for (final series in _host.series)
        series.copyWith(
          historyThrough: today,
        ),
    ];
    await _repository.upsertAll(reset);
    _host.replaceSeries(reset);
  }
}
