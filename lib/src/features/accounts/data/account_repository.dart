import '../domain/account_item.dart';

abstract interface class AccountRepository {
  Future<List<AccountItem>> loadAccounts();

  Future<void> saveAccounts(List<AccountItem> accounts);
}
