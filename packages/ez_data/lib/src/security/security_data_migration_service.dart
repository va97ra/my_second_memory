import 'dart:convert';

import '../accounts/encrypted_account_repository.dart';
import '../accounts/local_account_repository.dart';
import '../finance/encrypted_finance_repository.dart';
import '../finance/finance_repository.dart';
import 'package:ez_domain/ez_domain.dart';
import '../memory/encrypted_memory_repository.dart';
import '../memory/memory_repository.dart';
import '../media/media_storage.dart';
import '../recurrence/encrypted_recurrence_repository.dart';
import '../recurrence/encrypted_recurrence_exception_repository.dart';
import '../recurrence/recurrence_exception_repository.dart';
import '../recurrence/recurrence_repository.dart';
import '../shifts/encrypted_shift_schedule_repository.dart';
import '../shifts/local_shift_schedule_repository.dart';
import '../storage/local_storage_scope.dart';
import 'app_cipher.dart';
import 'encrypted_json_store.dart';
import 'secure_entity_backend.dart';

class SecurityDataMigrationSnapshot {
  const SecurityDataMigrationSnapshot({
    this.memoryItems,
    this.shiftSchedules,
    this.accounts,
    this.recurrenceSeries,
    this.recurrenceExceptions,
    this.financeEntries,
  });

  final List<MemoryItem>? memoryItems;
  final List<ShiftSchedule>? shiftSchedules;
  final List<AccountItem>? accounts;
  final List<RecurrenceSeries>? recurrenceSeries;
  final List<RecurrenceOccurrenceException>? recurrenceExceptions;
  final List<FinanceEntry>? financeEntries;
}

class SecurityDataMigrationService {
  const SecurityDataMigrationService(this.storage);

  final LocalStorageScope storage;

  Future<SecurityDataMigrationSnapshot> snapshotEncryptedData(
    AppCipher? cipher,
  ) async {
    if (cipher == null) {
      return const SecurityDataMigrationSnapshot();
    }

    final store = EncryptedJsonStore(cipher: cipher);
    final plainMemory = storage.memoryRepository;
    final plainRecurrence = storage.recurrenceRepository;
    final plainRecurrenceExceptions = storage.recurrenceExceptionRepository;
    final backend = storage.secureEntityBackend;
    return SecurityDataMigrationSnapshot(
      memoryItems: await EncryptedMemoryRepository(
        store: store,
        plainRepository: plainMemory,
        backend: backend,
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
      recurrenceExceptions: await EncryptedRecurrenceExceptionRepository(
        store: store,
        plainRepository: plainRecurrenceExceptions,
        backend: backend,
      ).loadAll(),
      financeEntries: await EncryptedFinanceRepository(
        store: store,
        plainRepository: storage.financeRepository,
        backend: backend,
      ).loadAll(),
    );
  }

  Future<void> encryptPlainData({
    required AppCipher cipher,
    required SecurityDataMigrationSnapshot snapshot,
  }) async {
    final repositories = _EncryptedRepositories(cipher, storage);
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
      if (snapshot.recurrenceExceptions != null) {
        await repositories.recurrenceExceptions
            .replaceAll(snapshot.recurrenceExceptions!);
      } else {
        await repositories.recurrenceExceptions.loadAll();
      }
      await repositories.plainRecurrenceExceptions.replaceAll(const []);
      final financeEntries =
          snapshot.financeEntries ?? await repositories.plainFinance.loadAll();
      await repositories.finance.replaceAll(financeEntries);
      final verifiedFinance = await repositories.finance.loadAll();
      if (!_sameFinanceEntries(financeEntries, verifiedFinance)) {
        throw StateError('Encrypted finance migration verification failed');
      }
      await repositories.plainFinance.replaceAll(const []);
      await mediaStorage.commitMigration(mediaMigration);
    } catch (_) {
      await mediaStorage.rollbackMigration(mediaMigration);
      rethrow;
    }
  }

  Future<void> decryptToPlainData(AppCipher cipher) async {
    final store = EncryptedJsonStore(cipher: cipher);

    final plainMemory = storage.memoryRepository;
    final backend = storage.secureEntityBackend;
    final memoryRepository = EncryptedMemoryRepository(
      store: store,
      plainRepository: plainMemory,
      backend: backend,
    );
    final encryptedItems = await memoryRepository.loadAll();
    final plainRecurrence = storage.recurrenceRepository;
    final plainRecurrenceExceptions = storage.recurrenceExceptionRepository;
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
      final exceptionRepository = EncryptedRecurrenceExceptionRepository(
        store: store,
        plainRepository: plainRecurrenceExceptions,
        backend: backend,
      );
      await plainRecurrenceExceptions.replaceAll(
        await exceptionRepository.loadAll(),
      );
      await backend?.replaceSecureEntities(
        EncryptedRecurrenceExceptionRepository.entityKind,
        const [],
      );
      await store.remove(EncryptedRecurrenceExceptionRepository.storageKey);

      final financeRepository = EncryptedFinanceRepository(
        store: store,
        plainRepository: storage.financeRepository,
        backend: backend,
      );
      final financeEntries = await financeRepository.loadAll();
      await storage.financeRepository.replaceAll(financeEntries);
      final verifiedFinance = await storage.financeRepository.loadAll();
      if (!_sameFinanceEntries(financeEntries, verifiedFinance)) {
        throw StateError('Plain finance migration verification failed');
      }
      await backend?.replaceSecureEntities(
        EncryptedFinanceRepository.entityKind,
        const [],
      );
      await store.remove(EncryptedFinanceRepository.storageKey);
      await mediaStorage.commitMigration(mediaMigration);
    } catch (_) {
      await mediaStorage.rollbackMigration(mediaMigration);
      rethrow;
    }
  }
}

bool _sameFinanceEntries(List<FinanceEntry> first, List<FinanceEntry> second) {
  final firstJson = first.map((item) => jsonEncode(item.toJson())).toList()
    ..sort();
  final secondJson = second.map((item) => jsonEncode(item.toJson())).toList()
    ..sort();
  if (firstJson.length != secondJson.length) return false;
  for (var index = 0; index < firstJson.length; index++) {
    if (firstJson[index] != secondJson[index]) return false;
  }
  return true;
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
  _EncryptedRepositories(AppCipher cipher, LocalStorageScope storage)
      : store = EncryptedJsonStore(cipher: cipher),
        plainMemory = storage.memoryRepository,
        plainRecurrence = storage.recurrenceRepository,
        plainRecurrenceExceptions = storage.recurrenceExceptionRepository,
        plainFinance = storage.financeRepository,
        backend = storage.secureEntityBackend;

  final EncryptedJsonStore store;
  final MemoryRepository plainMemory;
  final RecurrenceRepository plainRecurrence;
  final RecurrenceExceptionRepository plainRecurrenceExceptions;
  final FinanceRepository plainFinance;
  final SecureEntityBackend? backend;

  EncryptedMemoryRepository get memory => EncryptedMemoryRepository(
        store: store,
        plainRepository: plainMemory,
        backend: backend,
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

  EncryptedRecurrenceExceptionRepository get recurrenceExceptions =>
      EncryptedRecurrenceExceptionRepository(
        store: store,
        plainRepository: plainRecurrenceExceptions,
        backend: backend,
      );

  EncryptedFinanceRepository get finance => EncryptedFinanceRepository(
        store: store,
        plainRepository: plainFinance,
        backend: backend,
      );
}
