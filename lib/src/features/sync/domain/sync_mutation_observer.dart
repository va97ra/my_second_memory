import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class SyncMutationObserver {
  void memoryChanged();
  Future<void> memoryDeleted(String id, DateTime deletedAt);
  void shiftSchedulesChanged();
  Future<void> shiftScheduleDeleted(String id, DateTime deletedAt);
  void accountsChanged();
  Future<void> accountDeleted(String id, DateTime deletedAt);
  void recurrenceSeriesChanged();
  Future<void> recurrenceSeriesDeleted(String id, DateTime deletedAt);
  void recurrenceExceptionsChanged();
  Future<void> recurrenceExceptionDeleted(String id, DateTime deletedAt);
}

class NoopSyncMutationObserver implements SyncMutationObserver {
  const NoopSyncMutationObserver();

  @override
  void memoryChanged() {}

  @override
  Future<void> memoryDeleted(String id, DateTime deletedAt) async {}

  @override
  void shiftSchedulesChanged() {}

  @override
  Future<void> shiftScheduleDeleted(String id, DateTime deletedAt) async {}

  @override
  void accountsChanged() {}

  @override
  Future<void> accountDeleted(String id, DateTime deletedAt) async {}

  @override
  void recurrenceSeriesChanged() {}

  @override
  Future<void> recurrenceSeriesDeleted(String id, DateTime deletedAt) async {}

  @override
  void recurrenceExceptionsChanged() {}

  @override
  Future<void> recurrenceExceptionDeleted(
    String id,
    DateTime deletedAt,
  ) async {}
}

final syncMutationObserverProvider = Provider<SyncMutationObserver>(
  (ref) => const NoopSyncMutationObserver(),
);
