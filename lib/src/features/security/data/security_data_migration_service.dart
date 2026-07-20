import '../../accounts/data/encrypted_account_repository.dart';
import '../../accounts/data/local_account_repository.dart';
import '../../accounts/domain/account_item.dart';
import '../../memory_items/data/encrypted_memory_repository.dart';
import '../../memory_items/data/memory_repository_factory.dart';
import '../../memory_items/data/memory_repository.dart';
import '../../memory_items/domain/memory_item.dart';
import '../../media/data/media_storage.dart';
import '../../recurrence/data/encrypted_recurrence_repository.dart';
import '../../recurrence/data/recurrence_repository.dart';
import '../../recurrence/data/recurrence_repository_factory.dart';
import '../../recurrence/domain/recurrence_series.dart';
import '../../shift_schedules/data/encrypted_shift_schedule_repository.dart';
import '../../shift_schedules/data/local_shift_schedule_repository.dart';
import '../../shift_schedules/domain/shift_schedule.dart';
import 'app_cipher.dart';
import 'encrypted_json_store.dart';
import 'secure_entity_backend.dart';

class SecurityDataMigrationSnapshot {
  const SecurityDataMigrationSnapshot({
    this.memoryItems,
    this.shiftSchedules,
    this.accounts,
    this.recurrenceSeries,
  });

  final List<MemoryItem>? memoryItems;
  final List<ShiftSchedule>? shiftSchedules;
  final List<AccountItem>? accounts;
  final List<RecurrenceSeries>? recurrenceSeries;
}

class SecurityDataMigrationService {
  const SecurityDataMigrationService();

  Future<SecurityDataMigrationSnapshot> snapshotEncryptedData(
    AppCipher? cipher,
  ) async {
    if (cipher == null) {
      return const SecurityDataMigrationSnapshot();
    }

    final store = EncryptedJsonStore(cipher: cipher);
    final plainMemory = createMemoryRepository();
    final plainRecurrence = createRecurrenceRepository();
    final backend = plainMemory is SecureEntityBackend
        ? plainMemory as SecureEntityBackend
        : null;
    try {
      return SecurityDataMigrationSnapshot(
        memoryItems: await EncryptedMemoryRepository(
          store: store,
          plainRepository: plainMemory,
        ).loadAll(),
        shiftSchedules: await EncryptedShiftScheduleRepository(
          store: store,
          plainRepository: const LocalShiftScheduleRepository(),
          backend: backend,
        ).loadSchedules(),
        accounts: await EncryptedAccountRepository(
          store: store,
          plainRepository: const LocalAccountRepository(),
          backend: backend,
        ).loadAccounts(),
        recurrenceSeries: await EncryptedRecurrenceRepository(
          store: store,
          plainRepository: plainRecurrence,
          backend: backend,
        ).loadAll(),
      );
    } finally {
      await plainMemory.close();
      await plainRecurrence.close();
    }
  }

  Future<void> encryptPlainData({
    required AppCipher cipher,
    required SecurityDataMigrationSnapshot snapshot,
  }) async {
    final repositories = _EncryptedRepositories(cipher);
    final mediaStorage = MediaStorage();
    Map<String, String> mediaMigration = const {};
    try {
      final sourceItems =
          snapshot.memoryItems ?? await repositories.plainMemory.loadAll();
      mediaMigration = await mediaStorage.stageEncryption(
        _mediaPaths(sourceItems),
        cipher,
      );
      await repositories.memory.replaceAll(
        _mapMediaPaths(sourceItems, mediaMigration),
      );
      final verifiedItems = await repositories.memory.loadAll();
      if (verifiedItems.length != sourceItems.length) {
        throw StateError('Encrypted memory verification failed');
      }
      await repositories.plainMemory.replaceAll(const []);

      if (snapshot.shiftSchedules != null) {
        await repositories.shifts.saveSchedules(snapshot.shiftSchedules!);
      } else {
        await repositories.shifts.loadSchedules();
      }
      await const LocalShiftScheduleRepository().saveSchedules(const []);

      if (snapshot.accounts != null) {
        await repositories.accounts.saveAccounts(snapshot.accounts!);
      } else {
        await repositories.accounts.loadAccounts();
      }
      await const LocalAccountRepository().saveAccounts(const []);

      if (snapshot.recurrenceSeries != null) {
        await repositories.recurrence.replaceAll(snapshot.recurrenceSeries!);
      } else {
        await repositories.recurrence.loadAll();
      }
      await repositories.plainRecurrence.replaceAll(const []);
      await mediaStorage.commitMigration(mediaMigration);
    } catch (_) {
      await mediaStorage.rollbackMigration(mediaMigration);
      rethrow;
    } finally {
      await repositories.close();
    }
  }

  Future<void> decryptToPlainData(AppCipher cipher) async {
    final store = EncryptedJsonStore(cipher: cipher);

    final plainMemory = createMemoryRepository();
    final backend = plainMemory is SecureEntityBackend
        ? plainMemory as SecureEntityBackend
        : null;
    final memoryRepository = EncryptedMemoryRepository(
      store: store,
      plainRepository: plainMemory,
    );
    final encryptedItems = await memoryRepository.loadAll();
    final plainRecurrence = createRecurrenceRepository();
    final mediaStorage = MediaStorage();
    final mediaMigration = await mediaStorage.stageDecryption(
      _mediaPaths(encryptedItems),
      cipher,
    );
    try {
      await plainMemory.replaceAll(
        _mapMediaPaths(encryptedItems, mediaMigration),
      );
      await backend?.replaceSecureEntities(
        EncryptedMemoryRepository.entityKind,
        const [],
      );
      await store.remove(EncryptedMemoryRepository.storageKey);

      const plainShifts = LocalShiftScheduleRepository();
      final shiftRepository = EncryptedShiftScheduleRepository(
        store: store,
        plainRepository: plainShifts,
        backend: backend,
      );
      await plainShifts.saveSchedules(await shiftRepository.loadSchedules());
      await backend?.replaceSecureEntities(
        EncryptedShiftScheduleRepository.entityKind,
        const [],
      );
      await store.remove(EncryptedShiftScheduleRepository.storageKey);

      const plainAccounts = LocalAccountRepository();
      final accountRepository = EncryptedAccountRepository(
        store: store,
        plainRepository: plainAccounts,
        backend: backend,
      );
      await plainAccounts.saveAccounts(await accountRepository.loadAccounts());
      await backend?.replaceSecureEntities(
        EncryptedAccountRepository.entityKind,
        const [],
      );
      await store.remove(EncryptedAccountRepository.storageKey);

      final recurrenceRepository = EncryptedRecurrenceRepository(
        store: store,
        plainRepository: plainRecurrence,
        backend: backend,
      );
      await plainRecurrence.replaceAll(await recurrenceRepository.loadAll());
      await backend?.replaceSecureEntities(
        EncryptedRecurrenceRepository.entityKind,
        const [],
      );
      await store.remove(EncryptedRecurrenceRepository.storageKey);
      await mediaStorage.commitMigration(mediaMigration);
    } catch (_) {
      await mediaStorage.rollbackMigration(mediaMigration);
      rethrow;
    } finally {
      await plainMemory.close();
      await plainRecurrence.close();
    }
  }
}

Set<String> _mediaPaths(List<MemoryItem> items) => {
      for (final item in items) ...[
        ...item.imagePaths,
        if (item.audioPath != null) item.audioPath!,
      ],
    };

List<MemoryItem> _mapMediaPaths(
  List<MemoryItem> items,
  Map<String, String> mapping,
) {
  return [
    for (final item in items)
      item.copyWith(
        imagePaths: [for (final path in item.imagePaths) mapping[path] ?? path],
        audioPath: item.audioPath == null
            ? null
            : mapping[item.audioPath!] ?? item.audioPath,
      ),
  ];
}

class _EncryptedRepositories {
  _EncryptedRepositories(AppCipher cipher)
      : store = EncryptedJsonStore(cipher: cipher),
        plainMemory = createMemoryRepository(),
        plainRecurrence = createRecurrenceRepository();

  final EncryptedJsonStore store;
  final MemoryRepository plainMemory;
  final RecurrenceRepository plainRecurrence;

  SecureEntityBackend? get backend => plainMemory is SecureEntityBackend
      ? plainMemory as SecureEntityBackend
      : null;

  EncryptedMemoryRepository get memory => EncryptedMemoryRepository(
        store: store,
        plainRepository: plainMemory,
      );

  EncryptedShiftScheduleRepository get shifts =>
      EncryptedShiftScheduleRepository(
        store: store,
        plainRepository: const LocalShiftScheduleRepository(),
        backend: backend,
      );

  EncryptedAccountRepository get accounts => EncryptedAccountRepository(
        store: store,
        plainRepository: const LocalAccountRepository(),
        backend: backend,
      );

  EncryptedRecurrenceRepository get recurrence => EncryptedRecurrenceRepository(
        store: store,
        plainRepository: plainRecurrence,
        backend: backend,
      );

  Future<void> close() async {
    await plainMemory.close();
    await plainRecurrence.close();
  }
}
