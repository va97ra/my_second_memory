import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';

/// Общее для тестов синхронизации: прогон движка, запись и два
/// поддельных хранилища — тумбстоуны и облако.
Future<SyncRunResult> sync({
  required SyncRemote remote,
  required AppCipher cipher,
  SyncTombstoneStore tombstones = const SyncTombstoneStore(),
  List<MemoryItem> memoryItems = const [],
  Future<void> Function(List<MemoryItem>)? replaceMemoryItems,
  required List<ShiftSchedule> shifts,
  required Future<void> Function(List<ShiftSchedule>) replaceShifts,
  required List<AccountItem> accounts,
  required Future<void> Function(List<AccountItem>) replaceAccounts,
  List<RecurrenceSeries> recurrenceSeries = const [],
  Future<void> Function(List<RecurrenceSeries>)? replaceRecurrenceSeries,
  List<RecurrenceOccurrenceException> recurrenceExceptions = const [],
  Future<void> Function(List<RecurrenceOccurrenceException>)?
      replaceRecurrenceExceptions,
  List<FinanceEntry> financeEntries = const [],
  Future<void> Function(List<FinanceEntry>)? replaceFinanceEntries,
  List<SavedToolCalculation> toolCalculations = const [],
  Future<void> Function(List<SavedToolCalculation>)? replaceToolCalculations,
}) {
  return AppSyncEngine(
    remote: remote,
    cipher: cipher,
    tombstones: tombstones,
  ).synchronize(
    memoryItems: memoryItems,
    replaceMemoryItems: replaceMemoryItems ?? (_) async {},
    shiftSchedules: shifts,
    replaceShiftSchedules: replaceShifts,
    accounts: accounts,
    replaceAccounts: replaceAccounts,
    recurrenceSeries: recurrenceSeries,
    replaceRecurrenceSeries: replaceRecurrenceSeries ?? (_) async {},
    recurrenceExceptions: recurrenceExceptions,
    replaceRecurrenceExceptions: replaceRecurrenceExceptions ?? (_) async {},
    financeEntries: financeEntries,
    replaceFinanceEntries: replaceFinanceEntries ?? (_) async {},
    toolCalculations: toolCalculations,
    replaceToolCalculations: replaceToolCalculations ?? (_) async {},
  );
}

MemoryItem memoryItem(String id, String title, DateTime date) => MemoryItem(
      id: id,
      type: MemoryType.note,
      title: title,
      memoryDate: date,
      createdAt: date,
      updatedAt: date,
    );

class MemoryTombstoneStore extends SyncTombstoneStore {
  final _values = <SyncEntityKind, Map<String, DateTime>>{};

  @override
  Future<Map<String, DateTime>> read(
    String userId, {
    SyncEntityKind kind = SyncEntityKind.memoryItem,
  }) async =>
      {...?_values[kind]};

  @override
  Future<void> write(
    String userId,
    Map<String, DateTime> next, {
    SyncEntityKind kind = SyncEntityKind.memoryItem,
  }) async {
    _values[kind] = {...next};
  }

  @override
  Future<void> markDeleted(
    String userId,
    String id,
    DateTime deletedAt, {
    SyncEntityKind kind = SyncEntityKind.memoryItem,
  }) async {
    (_values[kind] ??= {})[id] = deletedAt;
  }
}

class SyncRemote implements SyncRemoteStore {
  final storedEntities = <String, SyncRemoteEntity>{};

  @override
  String? get currentUserEmail => 'test@example.com';

  @override
  String? get currentUserId => 'user';

  @override
  Future<void> applyEntities(List<SyncRemoteEntity> entities) async {
    for (final entity in entities) {
      storedEntities['${entity.kind.storageName}:${entity.entityId}'] = entity;
    }
  }

  @override
  Future<void> createVaultProfile(SyncVaultProfile profile) async {}

  @override
  Future<List<SyncRemoteEntity>> fetchEntities() async =>
      storedEntities.values.toList();

  @override
  Future<SyncVaultProfile?> fetchVaultProfile() async => null;

  @override
  Future<bool> signInWithGoogle() async => true;

  @override
  Future<void> signOut() async {}

  @override
  Stream<void> watchAuthenticatedSession() => const Stream.empty();

  @override
  Stream<void> watchChanges() => const Stream.empty();
}
