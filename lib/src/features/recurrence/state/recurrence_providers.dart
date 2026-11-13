import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ez_domain/ez_domain.dart';
import '../../calendar/state/calendar_today_provider.dart';
import '../../memory_items/memory_items.dart';
import 'package:ez_data/ez_data.dart';
import '../../security/security.dart';
import 'recurrence_exception_controller.dart';
import 'recurrence_series_controller.dart';
import '../../../app/local_storage_scope_provider.dart';

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

final recurrenceExceptionControllerProvider = NotifierProvider<
    RecurrenceExceptionController, List<RecurrenceOccurrenceException>>(
  RecurrenceExceptionController.new,
);

final recurrenceSeriesControllerProvider =
    NotifierProvider<RecurrenceSeriesController, List<RecurrenceSeries>>(
  RecurrenceSeriesController.new,
);

final recurrenceLoadProvider = FutureProvider<void>((ref) {
  return ref.watch(recurrenceSeriesControllerProvider.notifier).load();
});

/// Проекция повторов на текущие данные: строится один раз на их изменение,
/// а ячейки, дни и лента берут из неё свои диапазоны.
final recurrenceProjectionProvider = Provider<RecurrenceProjection>((ref) {
  return RecurrenceProjection(
    series: ref.watch(recurrenceSeriesControllerProvider),
    exceptions: ref.watch(recurrenceExceptionControllerProvider),
    persistedItems: ref.watch(memoryItemsControllerProvider),
  );
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
  return ref
      .watch(recurrenceProjectionProvider)
      .itemsForRange(range.start, range.end);
});

/// Ближайшее вхождение каждого повтора, по одному на серию. Вхождений у
/// повтора бесконечно много: в списке всех дат он лежит одной строкой.
/// Самый редкий повтор случается раз в год, поэтому смотрим на год вперёд.
///
/// Считается от сегодняшнего дня и пересчитывается, когда он сменился:
/// иначе после полуночи ближайшим оставалось вчерашнее вхождение.
final nextRecurrenceItemsProvider = Provider<List<MemoryItem>>((ref) {
  final today = ref.watch(calendarTodayProvider);
  final items = ref.watch(
    recurrenceItemsForRangeProvider(
      RecurrenceRange(today, DateTime(today.year + 1, today.month, today.day)),
    ),
  );
  final nearest = <String, MemoryItem>{};
  for (final item in items) {
    final series = item.seriesId;
    if (series == null) continue;
    final known = nearest[series];
    if (known == null || item.memoryDate.isBefore(known.memoryDate)) {
      nearest[series] = item;
    }
  }
  return nearest.values.toList(growable: false);
});

final recurrenceItemByIdProvider =
    Provider.family<MemoryItem?, String>((ref, id) {
  return ref.watch(recurrenceProjectionProvider).itemById(id);
});
