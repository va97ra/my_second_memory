import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:ez_data/ez_data.dart';
import 'package:ez_data/src/security/password_key.dart';
import 'package:flutter_test/flutter_test.dart';

/// Самая долгая пауза главного потока, пока идёт [work]: таймер тикает
/// каждые 2 мс, и всё, что дольше, — время, когда интерфейс стоял.
Future<Duration> longestPause(Future<void> Function() work) async {
  final watch = Stopwatch()..start();
  var last = watch.elapsed;
  var longest = Duration.zero;
  void tick() {
    final now = watch.elapsed;
    if (now - last > longest) longest = now - last;
    last = now;
  }

  final timer = Timer.periodic(const Duration(milliseconds: 2), (_) => tick());
  await work();
  tick();
  timer.cancel();
  return longest;
}

/// О4: шифрование фото и вывод ключа из PIN не держат главный поток —
/// иначе на вводе PIN и при сохранении снимка интерфейс замирает.
void main() {
  final cipher = AppCipher.fromKeyBytes(List.filled(32, 1));
  final photo = Uint8List(16 * 1024 * 1024);

  test('encrypting a large photo leaves the main thread free', () async {
    late Uint8List encrypted;

    final pause = await longestPause(() async {
      encrypted = await cipher.encryptBytes(photo);
    });

    expect(pause, lessThan(const Duration(milliseconds: 100)));
    expect(encrypted.length, photo.length + 29);
  });

  test('decrypting a large photo leaves the main thread free', () async {
    final encrypted = await cipher.encryptBytes(photo);
    late Uint8List clear;

    final pause = await longestPause(() async {
      clear = await cipher.decryptBytes(encrypted);
    });

    expect(pause, lessThan(const Duration(milliseconds: 100)));
    expect(clear.length, photo.length);
  });

  // Эталоны сняты с кода до переноса в изолят. Если они разойдутся, замок
  // и копии, сделанные прежней версией, больше не откроются.
  group('the same keys and format as before', () {
    test('a PIN gives the same key', () async {
      final fromPin = await AppCipher.fromPin(
        pin: '1234',
        salt: List<int>.filled(16, 7),
      );

      expect(
        base64Encode(fromPin.exportKeyBytes()),
        'Tt7GN70gZ4f0zzdvfqqZOviQTvb3YCZR3yhrJEBM/Wg=',
      );
    });

    test('a backup password gives the same key', () async {
      expect(
        base64Encode(
          await derivePasswordKey('пароль копии', List<int>.filled(16, 3)),
        ),
        'l/1QggdMOQbLpZPY93x0gCNMh44mBpoxyYIVTGErqsI=',
      );
    });

    test('a photo encrypted by the previous version opens', () async {
      final fromPin = await AppCipher.fromPin(
        pin: '1234',
        salt: List<int>.filled(16, 7),
      );

      expect(
        utf8.decode(await fromPin.decryptBytes(base64Decode(
          'AR5qm8jPsr3VOIeOXYMGk+vOoUAJbVkHg2FwWDI3wf/qgt6BtfAmJ04=',
        ))),
        'снимок',
      );
    });
  });
}
