import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import 'background_work.dart';

/// Итерации PBKDF2. Ими выведены ключи замка и всех резервных копий: другое
/// число — другой ключ, и старое хранилище или копия больше не откроются.
const passwordKeyIterations = 120000;

/// Ключ из PIN или пароля копии: PBKDF2-HMAC-SHA256, 256 бит.
///
/// Вывод занимает заметную долю секунды и идёт в отдельном изоляте: на
/// главном потоке он дёргал бы анимацию ввода PIN.
Future<List<int>> derivePasswordKey(String password, List<int> salt) {
  final passwordBytes = utf8.encode(password);
  final nonce = List<int>.of(salt);
  return inBackground(() async {
    final key = await Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: passwordKeyIterations,
      bits: 256,
    ).deriveKey(secretKey: SecretKey(passwordBytes), nonce: nonce);
    return key.extractBytes();
  });
}
