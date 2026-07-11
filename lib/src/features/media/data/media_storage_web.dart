import 'package:file_selector/file_selector.dart';

import '../../security/data/app_cipher.dart';

class MediaStorage {
  Future<String> saveImage(XFile file) async => file.path;

  Future<String> createVoicePath() async => '';

  Future<void> deleteOwnedFiles(
    Iterable<String> paths, {
    required Set<String> usedPaths,
  }) async {}

  Future<void> cleanOrphans(Set<String> usedPaths) async {}

  Future<Map<String, String>> stageEncryption(
    Iterable<String> paths,
    AppCipher cipher,
  ) async =>
      const {};

  Future<Map<String, String>> stageDecryption(
    Iterable<String> paths,
    AppCipher cipher,
  ) async =>
      const {};

  Future<void> commitMigration(Map<String, String> mapping) async {}

  Future<void> rollbackMigration(Map<String, String> mapping) async {}

  Future<List<int>> readEncryptedBytes(String path, AppCipher cipher) async =>
      const [];

  Future<String> materializeAudio(String path, AppCipher cipher) async => path;

  Future<void> deleteTemporaryAudio(String path) async {}
}
