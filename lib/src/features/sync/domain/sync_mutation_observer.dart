import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class SyncMutationObserver {
  void memoryChanged();
  Future<void> memoryDeleted(String id, DateTime deletedAt);
}

class NoopSyncMutationObserver implements SyncMutationObserver {
  const NoopSyncMutationObserver();

  @override
  void memoryChanged() {}

  @override
  Future<void> memoryDeleted(String id, DateTime deletedAt) async {}
}

final syncMutationObserverProvider = Provider<SyncMutationObserver>(
  (ref) => const NoopSyncMutationObserver(),
);
