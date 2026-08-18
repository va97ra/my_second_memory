import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/sync_mutation_observer.dart';
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
        .recordDeletion(id, deletedAt);
  }
}
