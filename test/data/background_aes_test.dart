import 'package:cryptography/cryptography.dart';
import 'package:ez_data/src/security/background_aes.dart';
import 'package:flutter_test/flutter_test.dart';

/// Копии, снятые до переноса шифрования в изолят, должны открываться, а
/// новые — открываться старым способом: формат не меняется.
void main() {
  final key = List<int>.generate(32, (index) => index);
  final nonce = List<int>.generate(12, (index) => 100 + index);
  final clear = List<int>.generate(4096, (index) => index % 251);

  test('шифр в изоляте совпадает с обычным AES-GCM байт в байт', () async {
    final inline = await AesGcm.with256bits().encrypt(
      clear,
      secretKey: SecretKey(key),
      nonce: nonce,
    );
    final background = await aesGcmSeal(clear, key: key, nonce: nonce);

    expect(background.cipherText, inline.cipherText);
    expect(background.mac, inline.mac);
    expect(await aesGcmOpen(inline, key: key), clear);
  });

  test('чужой ключ не открывает', () async {
    final box = await aesGcmSeal(clear, key: key, nonce: nonce);
    await expectLater(
      aesGcmOpen(box, key: List<int>.filled(32, 9)),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
  });
}
