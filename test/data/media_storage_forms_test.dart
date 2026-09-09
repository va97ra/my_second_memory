import 'dart:io';
import 'dart:typed_data';

import 'package:ez_data/ez_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Вложение на диске живёт в двух видах — открытом и зашифрованном, — и какой
/// из них настоящий, решает сам файл, а не состояние устройства. Здесь это
/// проверяется настоящими файлами и настоящим шифром.
void main() {
  late Directory root;
  final atRest = AppCipher.fromKeyBytes(List.filled(32, 5));

  setUp(() {
    root = Directory.systemTemp.createTempSync('media_forms');
    MediaStorage.debugRoot = root.path;
  });

  tearDown(() {
    MediaStorage.debugRoot = null;
    root.deleteSync(recursive: true);
  });

  final photo = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3, 4]);

  test('a file that arrived over sync is read back on a device with a PIN',
      () async {
    final storage = MediaStorage();
    await storage.writePlainBytes('image_1.jpg', photo, atRest);

    expect(
      File(p.join(root.path, 'image_1.jpg.ezm')).existsSync(),
      isTrue,
      reason: 'с PIN файл кладётся зашифрованным',
    );
    expect(await storage.exists('image_1.jpg'), isTrue);
    expect(await storage.readPlainBytes('image_1.jpg', atRest), photo);
  });

  test('a file added on this device stays plain and is still read back',
      () async {
    final storage = MediaStorage();
    await storage.writePlainBytes('image_2.jpg', photo, null);

    expect(File(p.join(root.path, 'image_2.jpg')).existsSync(), isTrue);
    // Ключ есть, а файл открытый: расшифровывать нечего, и это не ошибка.
    expect(await storage.readPlainBytes('image_2.jpg', atRest), photo);
  });

  test('both forms live side by side on one device', () async {
    final storage = MediaStorage();
    await storage.writePlainBytes('image_local.jpg', photo, null);
    await storage.writePlainBytes('image_synced.jpg', photo, atRest);

    expect(await storage.readPlainBytes('image_local.jpg', atRest), photo);
    expect(await storage.readPlainBytes('image_synced.jpg', atRest), photo);
  });

  test('a reference that arrived with a path or an .ezm tail still resolves',
      () async {
    final storage = MediaStorage();
    await storage.writePlainBytes('image_3.jpg', photo, atRest);

    for (final reference in [
      'image_3.jpg',
      'image_3.jpg.ezm',
      '/data/user/0/app/files/image_3.jpg',
      r'C:\Users\someone\Documents\image_3.jpg.ezm',
    ]) {
      expect(await storage.exists(reference), isTrue, reason: reference);
      expect(await storage.readPlainBytes(reference, atRest), photo,
          reason: reference);
    }
  });

  test('a fresh recording is protected on a device with a PIN', () async {
    final storage = MediaStorage();
    // Запись голоса идёт прямо в файл и на лету не шифруется.
    await File(p.join(root.path, 'voice_9.m4a')).writeAsBytes(photo);

    await storage.protectRecording('voice_9.m4a', atRest);

    expect(File(p.join(root.path, 'voice_9.m4a')).existsSync(), isFalse,
        reason: 'открытая копия не должна остаться на диске');
    expect(File(p.join(root.path, 'voice_9.m4a.ezm')).existsSync(), isTrue);
    expect(await storage.readPlainBytes('voice_9.m4a', atRest), photo);
  });

  test('without a PIN a fresh recording stays as it was', () async {
    final storage = MediaStorage();
    await File(p.join(root.path, 'voice_10.m4a')).writeAsBytes(photo);

    await storage.protectRecording('voice_10.m4a', null);

    expect(File(p.join(root.path, 'voice_10.m4a')).existsSync(), isTrue);
    expect(File(p.join(root.path, 'voice_10.m4a.ezm')).existsSync(), isFalse);
  });

  test('reading an encrypted file without the key fails loudly', () async {
    final storage = MediaStorage();
    await storage.writePlainBytes('image_4.jpg', photo, atRest);

    expect(
      () => storage.readPlainBytes('image_4.jpg', null),
      throwsA(isA<StateError>()),
    );
  });
}
