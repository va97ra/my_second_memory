import '../../accounts/data/encrypted_account_repository.dart';
import '../../accounts/data/local_account_repository.dart';
import '../../accounts/domain/account_item.dart';
import '../../memory_items/data/encrypted_memory_repository.dart';
import '../../memory_items/data/memory_repository_factory.dart';
import '../../memory_items/domain/memory_item.dart';
import '../../shift_schedules/data/encrypted_shift_schedule_repository.dart';
import '../../shift_schedules/data/local_shift_schedule_repository.dart';
import '../../shift_schedules/domain/shift_schedule.dart';
import 'app_cipher.dart';
import 'encrypted_json_store.dart';

class SecurityDataMigrationSnapshot {
  const SecurityDataMigrationSnapshot({
    this.memoryItems,
    this.shiftSchedules,
    this.accounts,
  });

  final List<MemoryItem>? memoryItems;
  final List<ShiftSchedule>? shiftSchedules;
  final List<AccountItem>? accounts;
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
    return SecurityDataMigrationSnapshot(
      memoryItems: await EncryptedMemoryRepository(
        store: store,
        plainRepository: createMemoryRepository(),
      ).loadAll(),
      shiftSchedules: await EncryptedShiftScheduleRepository(
        store: store,
        plainRepository: const LocalShiftScheduleRepository(),
      ).loadSchedules(),
      accounts: await EncryptedAccountRepository(
        store: store,
        plainRepository: const LocalAccountRepository(),
      ).loadAccounts(),
    );
  }

  Future<void> encryptPlainData({
    required AppCipher cipher,
    required SecurityDataMigrationSnapshot snapshot,
  }) async {
    final repositories = _EncryptedRepositories(cipher);

    if (snapshot.memoryItems != null) {
      await repositories.memory.replaceAll(snapshot.memoryItems!);
    } else {
      await repositories.memory.loadAll();
    }

    if (snapshot.shiftSchedules != null) {
      await repositories.shifts.saveSchedules(snapshot.shiftSchedules!);
    } else {
      await repositories.shifts.loadSchedules();
    }

    if (snapshot.accounts != null) {
      await repositories.accounts.saveAccounts(snapshot.accounts!);
    } else {
      await repositories.accounts.loadAccounts();
    }
  }

  Future<void> decryptToPlainData(AppCipher cipher) async {
    final store = EncryptedJsonStore(cipher: cipher);

    final plainMemory = createMemoryRepository();
    final memoryRepository = EncryptedMemoryRepository(
      store: store,
      plainRepository: plainMemory,
    );
    await plainMemory.replaceAll(await memoryRepository.loadAll());
    await store.remove(EncryptedMemoryRepository.storageKey);

    const plainShifts = LocalShiftScheduleRepository();
    final shiftRepository = EncryptedShiftScheduleRepository(
      store: store,
      plainRepository: plainShifts,
    );
    await plainShifts.saveSchedules(await shiftRepository.loadSchedules());
    await store.remove(EncryptedShiftScheduleRepository.storageKey);

    const plainAccounts = LocalAccountRepository();
    final accountRepository = EncryptedAccountRepository(
      store: store,
      plainRepository: plainAccounts,
    );
    await plainAccounts.saveAccounts(await accountRepository.loadAccounts());
    await store.remove(EncryptedAccountRepository.storageKey);
  }
}

class _EncryptedRepositories {
  _EncryptedRepositories(AppCipher cipher)
      : store = EncryptedJsonStore(cipher: cipher);

  final EncryptedJsonStore store;

  EncryptedMemoryRepository get memory => EncryptedMemoryRepository(
        store: store,
        plainRepository: createMemoryRepository(),
      );

  EncryptedShiftScheduleRepository get shifts =>
      EncryptedShiftScheduleRepository(
        store: store,
        plainRepository: const LocalShiftScheduleRepository(),
      );

  EncryptedAccountRepository get accounts => EncryptedAccountRepository(
        store: store,
        plainRepository: const LocalAccountRepository(),
      );
}
