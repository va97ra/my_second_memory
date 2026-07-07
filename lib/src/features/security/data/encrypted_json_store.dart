import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'app_cipher.dart';

class EncryptedJsonStore {
  const EncryptedJsonStore({
    required this.cipher,
    this.preferences,
  });

  final AppCipher cipher;
  final SharedPreferences? preferences;

  Future<bool> contains(String key) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    return prefs.containsKey(key);
  }

  Future<List<dynamic>> readList(String key) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    final clear = await cipher.decryptString(raw);
    return jsonDecode(clear) as List<dynamic>;
  }

  Future<void> writeList(String key, List<Object?> values) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    final encrypted = await cipher.encryptString(jsonEncode(values));
    await prefs.setString(key, encrypted);
  }
}
