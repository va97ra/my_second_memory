import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Ключ GigaChat владельца.
///
/// Лежит в защищённом хранилище устройства, как ключ синхронизации: это
/// секрет, и ни в резервную копию, ни в облако он не уезжает. На другом
/// устройстве ключ вводят заново.
class GigaChatKeyStore {
  GigaChatKeyStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'jarvis_gigachat_auth_key_v1';

  final FlutterSecureStorage _storage;

  Future<String?> read() async {
    final value = await _storage.read(key: _key);
    return value == null || value.trim().isEmpty ? null : value.trim();
  }

  Future<void> save(String authKey) =>
      _storage.write(key: _key, value: authKey.trim());

  Future<void> delete() => _storage.delete(key: _key);
}
