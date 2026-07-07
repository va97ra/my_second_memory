import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

class AppCipher {
  const AppCipher._(this._keyBytes);

  final List<int> _keyBytes;

  static final _algorithm = AesGcm.with256bits();

  static Future<AppCipher> fromPin({
    required String pin,
    required List<int> salt,
  }) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 120000,
      bits: 256,
    );
    final key = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(pin)),
      nonce: salt,
    );
    return AppCipher._(await key.extractBytes());
  }

  factory AppCipher.fromKeyBytes(List<int> keyBytes) {
    return AppCipher._(List<int>.unmodifiable(keyBytes));
  }

  List<int> exportKeyBytes() => List<int>.unmodifiable(_keyBytes);

  Future<String> encryptString(String value) async {
    final nonce = _randomBytes(12);
    final box = await _algorithm.encrypt(
      utf8.encode(value),
      secretKey: SecretKey(_keyBytes),
      nonce: nonce,
    );
    return jsonEncode({
      'nonce': base64Encode(box.nonce),
      'cipherText': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    });
  }

  Future<String> decryptString(String value) async {
    final decoded = jsonDecode(value) as Map<String, Object?>;
    final box = SecretBox(
      base64Decode(decoded['cipherText'] as String),
      nonce: base64Decode(decoded['nonce'] as String),
      mac: Mac(base64Decode(decoded['mac'] as String)),
    );
    final clear = await _algorithm.decrypt(
      box,
      secretKey: SecretKey(_keyBytes),
    );
    return utf8.decode(clear);
  }

  static List<int> randomSalt() => _randomBytes(16);

  static List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }
}
