import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local_storage/local_storage_scope_provider.dart';
import '../../security/data/encrypted_json_store.dart';
import '../../security/state/security_provider.dart';
import '../../sync/domain/sync_mutation_observer.dart';
import '../data/account_repository.dart';
import '../data/encrypted_account_repository.dart';
import '../data/local_account_repository.dart';
import '../domain/account_item.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final session = ref.watch(securitySessionProvider);
  final cipher = session.cipher;
  const plainRepository = LocalAccountRepository();
  if (session.hasPin && cipher != null) {
    return EncryptedAccountRepository(
      store: EncryptedJsonStore(cipher: cipher),
      plainRepository: plainRepository,
      backend: ref.watch(localStorageScopeProvider).secureEntityBackend,
    );
  }
  if (!session.hasPin) {
    return plainRepository;
  }
  return plainRepository;
});

final accountsControllerProvider =
    StateNotifierProvider<AccountsController, List<AccountItem>>((ref) {
  return AccountsController(
    ref.watch(accountRepositoryProvider),
    ref.watch(syncMutationObserverProvider),
  );
});

class AccountsController extends StateNotifier<List<AccountItem>> {
  AccountsController(this._repository, [this._sync]) : super(const []) {
    _loadFuture = _load();
  }

  final AccountRepository _repository;
  final SyncMutationObserver? _sync;
  late final Future<void> _loadFuture;

  Future<void> load() => _loadFuture;

  Future<void> _load() async {
    state = _sort(await _repository.loadAccounts());
  }

  Future<void> add(AccountItem account) async {
    await _loadFuture;
    state = _sort([...state, account.copyWith(updatedAt: DateTime.now())]);
    await _repository.saveAccounts(state);
    _sync?.accountsChanged();
  }

  Future<void> update(AccountItem account) async {
    await _loadFuture;
    final updated = account.copyWith(updatedAt: DateTime.now());
    state = _sort([
      for (final existing in state)
        if (existing.id == account.id) updated else existing,
    ]);
    await _repository.saveAccounts(state);
    _sync?.accountsChanged();
  }

  Future<void> delete(String id) async {
    await _loadFuture;
    final deletedAt = DateTime.now();
    state = [
      for (final account in state)
        if (account.id != id) account,
    ];
    await _repository.saveAccounts(state);
    await _sync?.accountDeleted(id, deletedAt);
  }

  Future<void> replaceAll(List<AccountItem> accounts) async {
    await _loadFuture;
    state = _sort(accounts);
    await _repository.saveAccounts(state);
  }

  List<AccountItem> _sort(List<AccountItem> accounts) {
    return [...accounts]..sort((a, b) {
        return a.serviceName.toLowerCase().compareTo(
              b.serviceName.toLowerCase(),
            );
      });
  }
}
