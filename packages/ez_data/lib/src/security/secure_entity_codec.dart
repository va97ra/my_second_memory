import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import 'app_cipher.dart';
import 'secure_entity_backend.dart';

class SecureEntityCodec {
  const SecureEntityCodec(this.cipher);

  final AppCipher cipher;

  Future<String> lookupKey(String id) async {
    final hash = await Sha256().hash(utf8.encode(id));
    return base64UrlEncode(hash.bytes);
  }

  Future<SecureEntityRecord> encode(
      String id, Map<String, Object?> json) async {
    return SecureEntityRecord(
      rowKey: base64UrlEncode(AppCipher.randomSalt()),
      lookupKey: await lookupKey(id),
      encryptedPayload: await cipher.encryptString(jsonEncode(json)),
    );
  }

  Future<Map<String, Object?>> decode(SecureEntityRecord record) async {
    return Map<String, Object?>.from(
      jsonDecode(await cipher.decryptString(record.encryptedPayload)) as Map,
    );
  }
}
