import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/sync_mutation_observer.dart';
import '../domain/sync_models.dart';
import 'sync_controller.dart';

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
}
