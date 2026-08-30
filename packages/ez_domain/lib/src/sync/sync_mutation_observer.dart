abstract interface class SyncMutationObserver {
  void memoryChanged();
  Future<void> memoryDeleted(String id, DateTime deletedAt);
  Future<DateTime?> memoryDeletedAt(String id);
  Future<Map<String, DateTime>> memoryDeletions();
  void shiftSchedulesChanged();
  Future<void> shiftScheduleDeleted(String id, DateTime deletedAt);
  void accountsChanged();
  Future<void> accountDeleted(String id, DateTime deletedAt);
  void recurrenceSeriesChanged();
  Future<void> recurrenceSeriesDeleted(String id, DateTime deletedAt);
  void recurrenceExceptionsChanged();
  Future<void> recurrenceExceptionDeleted(String id, DateTime deletedAt);
  void financeEntriesChanged();
  Future<void> financeEntryDeleted(String id, DateTime deletedAt);
}

class NoopSyncMutationObserver implements SyncMutationObserver {
  const NoopSyncMutationObserver();

  @override
  void memoryChanged() {}

  @override
  Future<void> memoryDeleted(String id, DateTime deletedAt) async {}

  @override
  Future<DateTime?> memoryDeletedAt(String id) async => null;

  @override
  Future<Map<String, DateTime>> memoryDeletions() async => const {};

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

  @override
  void financeEntriesChanged() {}

  @override
  Future<void> financeEntryDeleted(String id, DateTime deletedAt) async {}
}
