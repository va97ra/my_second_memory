import '../../security/data/encrypted_json_store.dart';
import '../../security/data/secure_entity_backend.dart';
import '../../security/data/secure_entity_codec.dart';
import '../domain/account_item.dart';
import 'account_repository.dart';

class EncryptedAccountRepository implements AccountRepository {
  const EncryptedAccountRepository({
    required this.store,
    this.plainRepository,
    this.backend,
  });

  static const storageKey = 'encrypted_accounts_v1';
  static const entityKind = 'account';

  final EncryptedJsonStore store;
  final AccountRepository? plainRepository;
  final SecureEntityBackend? backend;

  @override
  Future<List<AccountItem>> loadAccounts() async {
    final secureBackend = backend;
    if (secureBackend != null) {
      var rows = await secureBackend.loadSecureEntities(entityKind);
      if (rows.isEmpty) {
        final accounts = await _loadLegacyOrPlain();
        await _replaceRows(accounts);
        rows = await secureBackend.loadSecureEntities(entityKind);
        final verified = await _decodeRows(rows);
        if (verified.length != accounts.length) {
          throw StateError('Encrypted account migration verification failed');
        }
        await store.remove(storageKey);
        await plainRepository?.saveAccounts(const []);
        return verified;
      }
      return _decodeRows(rows);
    }
    if (!await store.contains(storageKey)) {
      final plain = plainRepository;
      if (plain == null) {
        return const [];
      }
      final accounts = await plain.loadAccounts();
      await saveAccounts(accounts);
      await plain.saveAccounts(const []);
      return accounts;
    }

    final decoded = await store.readList(storageKey);
    return decoded.map((entry) {
      return AccountItem.fromJson(Map<String, Object?>.from(entry as Map));
    }).toList();
  }

  @override
  Future<void> saveAccounts(List<AccountItem> accounts) async {
    if (backend != null) {
      await _replaceRows(accounts);
      return;
    }
    await store.writeList(
      storageKey,
      accounts.map((account) => account.toJson()).toList(),
    );
  }

  SecureEntityCodec get _codec => SecureEntityCodec(store.cipher);

  Future<List<AccountItem>> _loadLegacyOrPlain() async {
    if (await store.contains(storageKey)) {
      final decoded = await store.readList(storageKey);
      return decoded.map((entry) {
        return AccountItem.fromJson(Map<String, Object?>.from(entry as Map));
      }).toList();
    }
    return plainRepository?.loadAccounts() ?? Future.value(const []);
  }

  Future<List<AccountItem>> _decodeRows(List<SecureEntityRecord> rows) async {
    final accounts = <AccountItem>[];
    for (final row in rows) {
      accounts.add(AccountItem.fromJson(await _codec.decode(row)));
    }
    return accounts;
  }

  Future<void> _replaceRows(List<AccountItem> accounts) async {
    final records = <SecureEntityRecord>[];
    for (final account in accounts) {
      records.add(await _codec.encode(account.id, account.toJson()));
    }
    await backend!.replaceSecureEntities(entityKind, records);
  }
}
