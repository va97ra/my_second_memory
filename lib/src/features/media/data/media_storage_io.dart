import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class MediaStorage {
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
