import 'package:ez_domain/ez_domain.dart';

abstract interface class AccountRepository {
  Future<List<AccountItem>> loadAccounts();

  Future<void> saveAccounts(List<AccountItem> accounts);
}
