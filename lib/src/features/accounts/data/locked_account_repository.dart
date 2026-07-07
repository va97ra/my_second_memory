import '../domain/account_item.dart';
import 'account_repository.dart';

class LockedAccountRepository implements AccountRepository {
  const LockedAccountRepository();

  @override
  Future<List<AccountItem>> loadAccounts() async {
    return const [];
  }

  @override
  Future<void> saveAccounts(List<AccountItem> accounts) async {
    throw StateError('Accounts require PIN');
  }
}
