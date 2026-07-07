import '../../security/data/encrypted_json_store.dart';
import '../domain/account_item.dart';
import 'account_repository.dart';

class EncryptedAccountRepository implements AccountRepository {
  const EncryptedAccountRepository({required this.store});

  static const storageKey = 'encrypted_accounts_v1';

  final EncryptedJsonStore store;

  @override
  Future<List<AccountItem>> loadAccounts() async {
    final decoded = await store.readList(storageKey);
    return decoded.map((entry) {
      return AccountItem.fromJson(Map<String, Object?>.from(entry as Map));
    }).toList();
  }

  @override
  Future<void> saveAccounts(List<AccountItem> accounts) async {
    await store.writeList(
      storageKey,
      accounts.map((account) => account.toJson()).toList(),
    );
  }
}
