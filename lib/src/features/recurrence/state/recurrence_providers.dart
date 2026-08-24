import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ez_domain/ez_domain.dart';
import '../../memory_items/memory_items.dart';
import 'package:ez_data/ez_data.dart';
import '../../security/security.dart';
import 'recurrence_exception_controller.dart';
import 'recurrence_series_controller.dart';
import '../../sync/sync.dart';
import '../../../app/local_storage_scope_provider.dart';
import '../../../shared/state/notification_providers.dart';

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


