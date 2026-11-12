import 'package:cryptography/cryptography.dart';

import 'background_work.dart';

/// AES-256-GCM вне главного изолята.
///
/// Шифруются мегабайты — снимки, голос, резервная копия целиком: на главном
/// потоке это останавливало интерфейс. Ключ и данные передаются байтами, а
/// не объектами шифра: в изолят уходит только то, что нужно для работы.
Future<SecretBox> aesGcmSeal(
  List<int> clear, {
  required List<int> key,
  required List<int> nonce,
}) {
  final keyBytes = List<int>.of(key);
  return inBackground(
    () => AesGcm.with256bits().encrypt(
      clear,
      secretKey: SecretKey(keyBytes),
      nonce: nonce,
    ),
  );
}

/// Обратное к [aesGcmSeal]. Неверный ключ или испорченные байты — исключение
/// `SecretBoxAuthenticationError`, как и у самого AES-GCM.
Future<List<int>> aesGcmOpen(SecretBox box, {required List<int> key}) {
  final keyBytes = List<int>.of(key);
  return inBackground(
    () => AesGcm.with256bits().decrypt(box, secretKey: SecretKey(keyBytes)),
  );
}
