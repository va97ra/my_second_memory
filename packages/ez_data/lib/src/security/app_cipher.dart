import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'background_work.dart';
import 'password_key.dart';

class AppCipher {
  AppCipher._(List<int> keyBytes) : _keyBytes = Uint8List.fromList(keyBytes);

  final Uint8List _keyBytes;
  bool _isDestroyed = false;

  static final _algorithm = AesGcm.with256bits();

  static Future<AppCipher> fromPin({
    required String pin,
    required List<int> salt,
  }) async =>
      AppCipher._(await derivePasswordKey(pin, salt));

  factory AppCipher.fromKeyBytes(List<int> keyBytes) {
    return AppCipher._(keyBytes);
  }

  bool get isDestroyed => _isDestroyed;

  List<int> exportKeyBytes() => List<int>.unmodifiable(_activeKeyBytes);

  void destroy() {
    if (_isDestroyed) return;
    _keyBytes.fillRange(0, _keyBytes.length, 0);
    _isDestroyed = true;
  }

  List<int> get _activeKeyBytes {
    if (_isDestroyed) {
      throw StateError('Cipher key has been destroyed');
    }
    return _keyBytes;
  }

  Future<String> encryptString(String value) async {
    final nonce = _randomBytes(12);
    final box = await _algorithm.encrypt(
      utf8.encode(value),
      secretKey: SecretKey(_activeKeyBytes),
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
      secretKey: SecretKey(_activeKeyBytes),
    );
    return utf8.decode(clear);
  }

  /// Фото и голос: мегабайты, поэтому шифруются в отдельном изоляте — на
  /// главном потоке снимок в несколько мегабайт останавливал интерфейс на
  /// секунду. Формат: версия `1`, nonce 12 байт, MAC 16 байт, шифротекст.
  Future<Uint8List> encryptBytes(List<int> value) =>
      _sealMedia(value, List<int>.of(_activeKeyBytes), _randomBytes(12));

  Future<Uint8List> decryptBytes(List<int> value) {
    if (value.length < 29 || value.first != 1) {
      throw const FormatException('Invalid encrypted media');
    }
    return _openMedia(value, List<int>.of(_activeKeyBytes));
  }

  // Статические, чтобы замыкание для изолята захватывало только данные, а
  // не сам шифр.
  static Future<Uint8List> _sealMedia(
    List<int> value,
    List<int> key,
    List<int> nonce,
  ) =>
      inBackground(() async {
        final box = await AesGcm.with256bits().encrypt(
          value,
          secretKey: SecretKey(key),
          nonce: nonce,
        );
        return Uint8List(29 + box.cipherText.length)
          ..[0] = 1
          ..setRange(1, 13, box.nonce)
          ..setRange(13, 29, box.mac.bytes)
          ..setRange(29, 29 + box.cipherText.length, box.cipherText);
      });

  static Future<Uint8List> _openMedia(List<int> value, List<int> key) =>
      inBackground(() async {
        final clear = await AesGcm.with256bits().decrypt(
          SecretBox(
            value.sublist(29),
            nonce: value.sublist(1, 13),
            mac: Mac(value.sublist(13, 29)),
          ),
          secretKey: SecretKey(key),
        );
        return Uint8List.fromList(clear);
      });

  static List<int> randomSalt() => _randomBytes(16);

  static List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }
}
