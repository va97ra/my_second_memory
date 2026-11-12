import 'dart:io';

import 'package:drift/native.dart';
import 'package:ez_data/ez_data.dart';
import 'package:ez_data/ez_data_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../support/local_storage_test_support.dart';
import '../support/recurrence_test_support.dart';

/// Фото повторов шифруются вместе с остальными данными, когда задают PIN, и
/// открываются обратно, когда его снимают.
void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('series_media_pin');
    MediaStorage.debugRoot = root.path;
  });

  tearDown(() {
    MediaStorage.debugRoot = null;
    root.deleteSync(recursive: true);
  });

  bool plain(String name) => File(p.join(root.path, name)).existsSync();
  bool encrypted(String name) => File(
        p.join(root.path, '$name${MediaStorage.encryptedExtension}'),
      ).existsSync();

  test('series photos are encrypted with a PIN and opened without it',
      () async {
    SharedPreferences.setMockInitialValues({});
    final storage = TestLocalStorage(AppDatabase(NativeDatabase.memory()));
    addTearDown(storage.close);
    final (:series, :override) = seriesWithMedia();
    await storage.recurrenceRepository.replaceAll([series]);
    await storage.recurrenceExceptionRepository.replaceAll([override]);
    File(p.join(root.path, 'image_series.jpg')).writeAsBytesSync([1]);
    File(p.join(root.path, 'image_override.jpg')).writeAsBytesSync([2]);
    final cipher = await AppCipher.fromPin(
      pin: '1234',
      salt: List<int>.filled(16, 7),
    );
    addTearDown(cipher.destroy);
    final service = SecurityDataMigrationService(storage);

    await service.encryptPlainData(
      cipher: cipher,
      snapshot: const SecurityDataMigrationSnapshot(),
    );

    for (final name in ['image_series.jpg', 'image_override.jpg']) {
      expect(encrypted(name), isTrue, reason: '$name must be encrypted');
      expect(plain(name), isFalse, reason: '$name must not stay open');
    }

    await service.decryptToPlainData(cipher);

    for (final name in ['image_series.jpg', 'image_override.jpg']) {
      expect(plain(name), isTrue, reason: '$name must be opened back');
      expect(encrypted(name), isFalse);
    }
  });
}
