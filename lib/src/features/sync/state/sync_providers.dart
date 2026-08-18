import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../accounts/state/accounts_controller.dart';
import '../../memory_items/state/memory_items_controller.dart';
import '../../recurrence/state/recurrence_controller.dart';
import '../../security/state/security_provider.dart';
import '../../shift_schedules/state/shift_schedules_controller.dart';
import '../data/supabase_sync_remote_store.dart';
import '../data/sync_local_store.dart';
import '../data/sync_remote_store.dart';
import '../domain/sync_backend_config.dart';
import '../domain/sync_models.dart';
import '../domain/sync_mutation_observer.dart';
import 'sync_controller_impl.dart';
import 'sync_state.dart';

final syncBackendConfigProvider = Provider<SyncBackendConfig>(
  (ref) => SyncBackendConfig.fromEnvironment(),
);

final syncRemoteStoreProvider = Provider<SyncRemoteStore?>((ref) {
  if (!ref.watch(syncBackendConfigProvider).isConfigured) return null;
  return SupabaseSyncRemoteStore(Supabase.instance.client);
});

final syncKeyStoreProvider = Provider<SyncKeyStore>((ref) => SyncKeyStore());
final syncTombstoneStoreProvider =
    Provider<SyncTombstoneStore>((ref) => const SyncTombstoneStore());

final syncControllerProvider =
    StateNotifierProvider<SyncController, SyncState>((ref) {
  return SyncController(
    remote: ref.watch(syncRemoteStoreProvider),
    keyStore: ref.watch(syncKeyStoreProvider),
    tombstones: ref.watch(syncTombstoneStoreProvider),
    canAccessLocalData: () => ref.read(securitySessionProvider).isUnlocked,
    readMemoryItems: () async {
      await ref.read(memoryItemsControllerProvider.notifier).load();
      return ref.read(memoryItemsControllerProvider);
    },
    replaceMemoryItems: (items) =>
        ref.read(memoryItemsControllerProvider.notifier).replaceAll(items),
    readShiftSchedules: () async {
      await ref.read(shiftSchedulesControllerProvider.notifier).load();
      return ref.read(shiftSchedulesControllerProvider);
    },
    replaceShiftSchedules: (schedules) => ref
        .read(shiftSchedulesControllerProvider.notifier)
        .replaceAll(schedules),
    readAccounts: () async {
      await ref.read(accountsControllerProvider.notifier).load();
      return ref.read(accountsControllerProvider);
    },
    replaceAccounts: (accounts) =>
        ref.read(accountsControllerProvider.notifier).replaceAll(accounts),
    readRecurrenceSeries: () async {
      await ref.read(recurrenceSeriesControllerProvider.notifier).load();
      return ref.read(recurrenceSeriesControllerProvider);
    },
    replaceRecurrenceSeries: (series) => ref
        .read(recurrenceSeriesControllerProvider.notifier)
        .replaceAll(series),
    readRecurrenceExceptions: () async {
      await ref.read(recurrenceExceptionControllerProvider.notifier).load();
      return ref.read(recurrenceExceptionControllerProvider);
    },
    replaceRecurrenceExceptions: (exceptions) => ref
        .read(recurrenceExceptionControllerProvider.notifier)
        .replaceAll(exceptions),
  );
});

final appSyncMutationObserverProvider = Provider<SyncMutationObserver>((ref) {
  return _RiverpodSyncMutationObserver(ref);
});

class _RiverpodSyncMutationObserver implements SyncMutationObserver {
  const _RiverpodSyncMutationObserver(this.ref);

  final Ref ref;

  @override
  void memoryChanged() {
    ref.read(syncControllerProvider.notifier).schedule();
  }

  @override
  Future<void> memoryDeleted(String id, DateTime deletedAt) {
    return ref
        .read(syncControllerProvider.notifier)
        .recordDeletion(SyncEntityKind.memoryItem, id, deletedAt);
  }

  @override
  void shiftSchedulesChanged() {
    ref.read(syncControllerProvider.notifier).schedule();
  }

  @override
  Future<void> shiftScheduleDeleted(String id, DateTime deletedAt) {
    return ref.read(syncControllerProvider.notifier).recordDeletion(
          SyncEntityKind.shiftSchedule,
          id,
          deletedAt,
        );
  }

  @override
  void accountsChanged() {
    ref.read(syncControllerProvider.notifier).schedule();
  }

  @override
  Future<void> accountDeleted(String id, DateTime deletedAt) {
    return ref.read(syncControllerProvider.notifier).recordDeletion(
          SyncEntityKind.account,
          id,
          deletedAt,
        );
  }

  @override
  void recurrenceSeriesChanged() {
    ref.read(syncControllerProvider.notifier).schedule();
  }

  @override
  Future<void> recurrenceSeriesDeleted(String id, DateTime deletedAt) {
    return ref.read(syncControllerProvider.notifier).recordDeletion(
          SyncEntityKind.recurrenceSeries,
          id,
          deletedAt,
        );
  }

  @override
  void recurrenceExceptionsChanged() {
    ref.read(syncControllerProvider.notifier).schedule();
  }

  @override
  Future<void> recurrenceExceptionDeleted(String id, DateTime deletedAt) {
    return ref.read(syncControllerProvider.notifier).recordDeletion(
          SyncEntityKind.recurrenceException,
          id,
          deletedAt,
        );
  }
}
