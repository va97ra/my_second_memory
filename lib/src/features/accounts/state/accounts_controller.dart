import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../security/data/encrypted_json_store.dart';
import '../../security/state/security_provider.dart';
import '../data/account_repository.dart';
import '../data/encrypted_account_repository.dart';
import '../data/locked_account_repository.dart';
import '../domain/account_item.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final session = ref.watch(securitySessionProvider);
  final cipher = session.cipher;
  if (session.hasPin && cipher != null) {
    return EncryptedAccountRepository(
      store: EncryptedJsonStore(cipher: cipher),
    );
  }
  return const LockedAccountRepository();
});

final accountsControllerProvider =
    StateNotifierProvider<AccountsController, List<AccountItem>>((ref) {
  return AccountsController(ref.watch(accountRepositoryProvider));
});

class AccountsController extends StateNotifier<List<AccountItem>> {
  AccountsController(this._repository) : super(const []) {
    _loadFuture = _load();
  }

  final AccountRepository _repository;
  late final Future<void> _loadFuture;

  Future<void> _load() async {
    state = _sort(await _repository.loadAccounts());
  }

  Future<void> add(AccountItem account) async {
    await _loadFuture;
    state = _sort([...state, account]);
    await _repository.saveAccounts(state);
  }

  Future<void> update(AccountItem account) async {
    await _loadFuture;
    state = _sort([
      for (final existing in state)
        if (existing.id == account.id) account else existing,
    ]);
    await _repository.saveAccounts(state);
  }

  Future<void> delete(String id) async {
    await _loadFuture;
    state = [
      for (final account in state)
        if (account.id != id) account,
    ];
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
