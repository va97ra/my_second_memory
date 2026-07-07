import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/account_item.dart';
import 'account_repository.dart';

class LocalAccountRepository implements AccountRepository {
  const LocalAccountRepository();

  static const storageKey = 'accounts_v1';

  @override
  Future<List<AccountItem>> loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((entry) {
      return AccountItem.fromJson(Map<String, Object?>.from(entry as Map));
    }).toList();
  }

  @override
  Future<void> saveAccounts(List<AccountItem> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      jsonEncode(accounts.map((account) => account.toJson()).toList()),
    );
  }
}
