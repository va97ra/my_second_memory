import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local_storage/local_storage_scope_provider.dart';
import '../../memory_items/domain/memory_item.dart';
import '../../memory_items/state/memory_items_controller.dart';
import '../../notifications/data/notification_service.dart';
import '../../security/data/encrypted_json_store.dart';
import '../../security/data/secure_entity_backend.dart';
import '../../security/state/security_provider.dart';
import '../../sync/domain/sync_mutation_observer.dart';
import '../data/encrypted_recurrence_exception_repository.dart';
import '../data/encrypted_recurrence_repository.dart';
import '../data/recurrence_exception_repository.dart';
import '../data/recurrence_repository.dart';
import '../domain/recurrence_occurrence_exception.dart';
import '../domain/recurrence_projection_service.dart';
import '../domain/recurrence_series.dart';
import 'recurrence_exception_controller.dart';
import 'recurrence_series_controller.dart';

final plainRecurrenceRepositoryProvider = Provider<RecurrenceRepository>((ref) {
  return ref.watch(localStorageScopeProvider).recurrenceRepository;
});

final plainRecurrenceExceptionRepositoryProvider =
    Provider<RecurrenceExceptionRepository>((ref) {
  return ref.watch(localStorageScopeProvider).recurrenceExceptionRepository;
});

SecureEntityBackend? _secureBackend(Ref ref) {
  return ref.watch(localStorageScopeProvider).secureEntityBackend;
}

final recurrenceRepositoryProvider = Provider<RecurrenceRepository>((ref) {
  final session = ref.watch(securitySessionProvider);
  final plain = ref.watch(plainRecurrenceRepositoryProvider);
  if (session.hasPin && session.cipher != null) {
    return EncryptedRecurrenceRepository(
      store: EncryptedJsonStore(cipher: session.cipher!),
      plainRepository: plain,
      backend: _secureBackend(ref),
    );
  }
  return plain;
});

final recurrenceExceptionRepositoryProvider =
    Provider<RecurrenceExceptionRepository>((ref) {
  final session = ref.watch(securitySessionProvider);
  final plain = ref.watch(plainRecurrenceExceptionRepositoryProvider);
  if (session.hasPin && session.cipher != null) {
    return EncryptedRecurrenceExceptionRepository(
      store: EncryptedJsonStore(cipher: session.cipher!),
      plainRepository: plain,
      backend: _secureBackend(ref),
    );
  }
  return plain;
});

final recurrenceExceptionControllerProvider = StateNotifierProvider<
    RecurrenceExceptionController, List<RecurrenceOccurrenceException>>((ref) {
  return RecurrenceExceptionController(
    ref.watch(recurrenceExceptionRepositoryProvider),
    ref.watch(syncMutationObserverProvider),
  );
});

final recurrenceSeriesControllerProvider =
    StateNotifierProvider<RecurrenceSeriesController, List<RecurrenceSeries>>(
  (ref) => RecurrenceSeriesController(
    ref.watch(recurrenceRepositoryProvider),
    ref.watch(recurrenceExceptionControllerProvider.notifier),
    ref.watch(memoryItemsControllerProvider.notifier),
    ref.watch(notificationServiceProvider),
    ref.watch(syncMutationObserverProvider),
  ),
);

final recurrenceLoadProvider = FutureProvider<void>((ref) {
  return ref.watch(recurrenceSeriesControllerProvider.notifier).load();
});

final recurrenceProjectionServiceProvider =
    Provider<RecurrenceProjectionService>((ref) {
  return const RecurrenceProjectionService();
});

class RecurrenceRange {
  const RecurrenceRange(this.start, this.end);

  final DateTime start;
  final DateTime end;

  @override
  bool operator ==(Object other) =>
      other is RecurrenceRange &&
      dateKey(other.start) == dateKey(start) &&
      dateKey(other.end) == dateKey(end);

  @override
  int get hashCode => Object.hash(dateKey(start), dateKey(end));
}

final recurrenceItemsForRangeProvider =
    Provider.family<List<MemoryItem>, RecurrenceRange>((ref, range) {
  return ref.watch(recurrenceProjectionServiceProvider).itemsForRange(
        start: range.start,
        end: range.end,
        series: ref.watch(recurrenceSeriesControllerProvider),
        exceptions: ref.watch(recurrenceExceptionControllerProvider),
        persistedItems: ref.watch(memoryItemsControllerProvider),
      );
});

final recurrenceItemByIdProvider =
    Provider.family<MemoryItem?, String>((ref, id) {
  return ref.watch(recurrenceProjectionServiceProvider).itemById(
        id: id,
        series: ref.watch(recurrenceSeriesControllerProvider),
        exceptions: ref.watch(recurrenceExceptionControllerProvider),
        persistedItems: ref.watch(memoryItemsControllerProvider),
      );
});

class RecurrencePeriod {
  const RecurrencePeriod({
    required this.frequency,
    required this.start,
    required this.end,
  });

  final RecurrenceFrequency frequency;
  final DateTime start;
  final DateTime end;

  @override
  bool operator ==(Object other) =>
      other is RecurrencePeriod &&
      other.frequency == frequency &&
      dateKey(other.start) == dateKey(start) &&
      dateKey(other.end) == dateKey(end);

  @override
  int get hashCode => Object.hash(
        frequency,
        dateKey(start),
        dateKey(end),
      );
}

final recurringItemsForPeriodProvider =
    Provider.family<List<MemoryItem>, RecurrencePeriod>((ref, period) {
  final matchingSeries = [
    for (final series in ref.watch(recurrenceSeriesControllerProvider))
      if (series.isEnabled && series.frequency == period.frequency) series,
  ];
  final ids = {for (final series in matchingSeries) series.id};
  final projected =
      ref.watch(recurrenceProjectionServiceProvider).itemsForRange(
            start: period.start,
            end: period.end,
            series: matchingSeries,
            exceptions: ref.watch(recurrenceExceptionControllerProvider),
            persistedItems: ref.watch(memoryItemsControllerProvider),
          );
  final byId = <String, MemoryItem>{};
  for (final item in projected) {
    if (!item.isArchived) byId[item.id] = item;
  }
  for (final item in ref.watch(memoryItemsControllerProvider)) {
    if (item.isArchived || item.seriesId == null) continue;
    if (!ids.contains(item.seriesId)) continue;
    if (item.memoryDate.isBefore(period.start) ||
        item.memoryDate.isAfter(period.end)) {
      continue;
    }
    // A persisted occurrence contains the user's current done/archive state
    // and must win over an equivalent projection.
    byId[item.id] = item;
  }
  return byId.values.toList()..sort(compareOccurrences);
});

final recurringCurrentPeriodItemsProvider =
    Provider.family<List<MemoryItem>, RecurrenceFrequency>((ref, frequency) {
  final now = DateTime.now();
  final start = frequency == RecurrenceFrequency.monthly
      ? DateTime(now.year, now.month)
      : DateTime(now.year);
  final end = frequency == RecurrenceFrequency.monthly
      ? DateTime(now.year, now.month + 1, 0)
      : DateTime(now.year, 12, 31);
  return ref.watch(
    recurringItemsForPeriodProvider(
      RecurrencePeriod(frequency: frequency, start: start, end: end),
    ),
  );
});
