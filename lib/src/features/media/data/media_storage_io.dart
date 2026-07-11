import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../security/data/app_cipher.dart';

class MediaStorage {
  static const encryptedExtension = '.ezm';
  Future<String> saveImage(XFile file) async {
    final directory = await getApplicationDocumentsDirectory();
    final extension = _safeImageExtension(file.name);
    final destination = p.join(
      directory.path,
      'image_${DateTime.now().microsecondsSinceEpoch}$extension',
    );
    await file.saveTo(destination);
    return destination;
  }

  Future<String> createVoicePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return p.join(
      directory.path,
      'voice_${DateTime.now().microsecondsSinceEpoch}.m4a',
    );
  }

  Future<void> deleteOwnedFiles(
    Iterable<String> paths, {
    required Set<String> usedPaths,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final root = p.normalize(directory.path);
    for (final path in paths.toSet()) {
      if (usedPaths.contains(path) || !_isOwnedPath(path, root)) continue;
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
  }

  Future<void> cleanOrphans(Set<String> usedPaths) async {
    final directory = await getApplicationDocumentsDirectory();
    await for (final entity in directory.list()) {
      if (entity is! File || usedPaths.contains(entity.path)) continue;
      final name = p.basename(entity.path);
      if (name.startsWith('image_') || name.startsWith('voice_')) {
        await entity.delete();
      }
    }
  }

  Future<Map<String, String>> stageEncryption(
    Iterable<String> paths,
    AppCipher cipher,
  ) async {
    final mapping = <String, String>{};
    for (final path in paths.toSet()) {
      if (path.endsWith(encryptedExtension)) continue;
      final source = File(path);
      if (!await source.exists()) continue;
      final destination = '$path$encryptedExtension';
      await File(destination).writeAsBytes(
        await cipher.encryptBytes(await source.readAsBytes()),
        flush: true,
      );
      mapping[path] = destination;
    }
    return mapping;
  }

  Future<Map<String, String>> stageDecryption(
    Iterable<String> paths,
    AppCipher cipher,
  ) async {
    final mapping = <String, String>{};
    for (final path in paths.toSet()) {
      if (!path.endsWith(encryptedExtension)) continue;
      final source = File(path);
      if (!await source.exists()) continue;
      final destination =
          path.substring(0, path.length - encryptedExtension.length);
      await File(destination).writeAsBytes(
        await cipher.decryptBytes(await source.readAsBytes()),
        flush: true,
      );
      mapping[path] = destination;
    }
    return mapping;
  }

  Future<void> commitMigration(Map<String, String> mapping) async {
    for (final sourcePath in mapping.keys) {
      final source = File(sourcePath);
      if (await source.exists()) await source.delete();
    }
  }

  Future<void> rollbackMigration(Map<String, String> mapping) async {
    for (final destinationPath in mapping.values) {
      final destination = File(destinationPath);
      if (await destination.exists()) await destination.delete();
    }
  }

  Future<List<int>> readEncryptedBytes(String path, AppCipher cipher) async {
    return cipher.decryptBytes(await File(path).readAsBytes());
  }

  Future<String> materializeAudio(String path, AppCipher cipher) async {
    if (!path.endsWith(encryptedExtension)) return path;
    final cache = await getTemporaryDirectory();
    final destination = p.join(
      cache.path,
      'playing_${DateTime.now().microsecondsSinceEpoch}.m4a',
    );
    await File(destination).writeAsBytes(
      await readEncryptedBytes(path, cipher),
      flush: true,
    );
    return destination;
  }

  Future<void> deleteTemporaryAudio(String path) async {
    final file = File(path);
    if (p.basename(path).startsWith('playing_') && await file.exists()) {
      await file.delete();
    }
  }

  bool _isOwnedPath(String path, String root) {
    final normalized = p.normalize(path);
    if (p.dirname(normalized) != root) return false;
    final name = p.basename(normalized);
    return name.startsWith('image_') || name.startsWith('voice_');
  }

  String _safeImageExtension(String name) {
    final extension = p.extension(name).toLowerCase();
    return switch (extension) {
      '.jpg' || '.jpeg' || '.png' || '.gif' || '.webp' => extension,
      _ => '.jpg',
    };
  }
}
