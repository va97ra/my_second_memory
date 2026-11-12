import 'dart:convert';
import 'dart:typed_data';

import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';

/// Общее для тестов синхронизации: прогон движка, запись и два
/// поддельных хранилища — тумбстоуны и облако.
Future<SyncRunResult> sync({
  required SyncRemote remote,
  required AppCipher cipher,
  SyncTombstoneStore? tombstones,
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
  MediaSyncEngine? media,
  CloudSnapshot? snapshot,
}) {
  return AppSyncEngine(
    remote: remote,
    cipher: cipher,
    tombstones: tombstones ?? SyncTombstoneStore(),
    media: media,
    snapshot: snapshot,
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

/// Запись в том виде, в каком её отправляет в облако другое устройство.
Future<SyncRemoteEntity> encodedMemoryItem(
  AppCipher cipher,
  MemoryItem item,
) async =>
    SyncRemoteEntity(
      kind: SyncEntityKind.memoryItem,
      entityId: item.id,
      encryptedPayload: await cipher.encryptString(jsonEncode(item.toJson())),
      updatedAt: item.updatedAt,
    );

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

  /// Облачные вложения: имя → уже зашифрованные байты, как в бакете.
  final storedMedia = <String, Uint8List>{};

  @override
  Future<Set<String>> listMediaNames() async => storedMedia.keys.toSet();

  @override
  Future<void> uploadMedia(String name, Uint8List bytes) async {
    storedMedia[name] = bytes;
  }

  @override
  Future<Uint8List> downloadMedia(String name) async {
    final bytes = storedMedia[name];
    if (bytes == null) throw StateError('No media named $name');
    return bytes;
  }

  @override
  Future<void> deleteMedia(Iterable<String> names) async {
    for (final name in names) {
      storedMedia.remove(name);
    }
  }

  @override
  String? get currentUserEmail => 'test@example.com';

  @override
  String? get currentUserId => 'user';

  /// Ревизии раздаются, как на сервере: каждая записанная строка получает
  /// следующий номер.
  var _revision = 0;

  /// Сколько строк вернуло каждое чтение облака.
  final fetchedRows = <int>[];

  /// Сколько раз отправляли изменения и сколько строк в каждой отправке.
  final appliedBatches = <int>[];

  @override
  Future<void> applyEntities(List<SyncRemoteEntity> entities) async {
    appliedBatches.add(entities.length);
    entities.forEach(seed);
  }

  /// Кладёт строку в облако так, как её положил бы сервер, — со следующей
  /// ревизией. Так тест готовит облако, не считая это отправкой.
  void seed(SyncRemoteEntity entity) {
    storedEntities['${entity.kind.storageName}:${entity.entityId}'] =
        SyncRemoteEntity(
      kind: entity.kind,
      entityId: entity.entityId,
      encryptedPayload: entity.encryptedPayload,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
      revision: ++_revision,
    );
  }

  @override
  Future<void> createVaultProfile(SyncVaultProfile profile) async {}

  @override
  Future<List<SyncRemoteEntity>> fetchEntities({int afterRevision = 0}) async {
    final rows = [
      for (final entity in storedEntities.values)
        if (entity.revision > afterRevision) entity,
    ]..sort((a, b) => a.revision.compareTo(b.revision));
    fetchedRows.add(rows.length);
    return rows;
  }

  @override
  Future<SyncVaultProfile?> fetchVaultProfile() async => null;

  @override
  Future<bool> signInWithGoogle() async => true;

  @override
  Future<void> signOut() async {}

  @override
  Stream<void> watchAuthenticatedSession() => const Stream.empty();

  @override
  Stream<SyncRemoteEntity?> watchChanges() => const Stream.empty();
}

/// Вложения в памяти: настоящему хранилищу нужен каталог документов, которого
/// в тесте нет.
class FakeMediaStorage extends MediaStorage {
  FakeMediaStorage(this.files);

  final Map<String, Uint8List> files;
  bool atRestUsed = false;

  @override
  Future<bool> exists(String reference) async =>
      files.containsKey(MediaStorage.referenceFor(reference));

  @override
  Future<Uint8List> readPlainBytes(String reference, AppCipher? atRest) async {
    final bytes = files[MediaStorage.referenceFor(reference)];
    if (bytes == null) throw StateError('No file $reference');
    return bytes;
  }

  @override
  Future<void> writePlainBytes(
    String reference,
    Uint8List bytes,
    AppCipher? atRest,
  ) async {
    if (atRest != null) atRestUsed = true;
    files[MediaStorage.referenceFor(reference)] = bytes;
  }
}
