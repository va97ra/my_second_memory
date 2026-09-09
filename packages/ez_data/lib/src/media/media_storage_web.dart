import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

import '../security/app_cipher.dart';

class MediaStorage {
  static const encryptedExtension = '.ezm';

  /// В вебе файловой системы нет: снимок остаётся строкой внутри записи, и
  /// подставлять каталог некуда. Одноимённые методы существуют, чтобы общий
  /// код не знал, на какой он платформе.
  static Future<String> initialize() async => '';

  static set debugRoot(String? value) {}

  static String resolve(String reference, {bool encrypted = false}) =>
      reference;

  static String referenceFor(String path) => path;

  static bool isExternal(String value) => true;

  Future<String> saveImage(XFile file, AppCipher? atRest) async =>
      file.path;

  Future<void> protectRecording(String reference, AppCipher? atRest) async {}

  Future<String> createVoicePath() async => '';

  Future<void> writePlainBytes(
    String reference,
    Uint8List bytes,
    AppCipher? atRest,
  ) async {}

  Future<bool> exists(String reference) async => true;

  Future<Uint8List> readPlainBytes(String reference, AppCipher? atRest) async =>
      Uint8List(0);

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

  Future<String> materializeAudio(String path, AppCipher? atRest) async =>
      path;

  Future<void> deleteTemporaryAudio(String path) async {}
}
