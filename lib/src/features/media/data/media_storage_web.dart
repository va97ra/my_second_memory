import 'package:file_selector/file_selector.dart';

class MediaStorage {
  Future<String> saveImage(XFile file) async => file.path;

  Future<String> createVoicePath() async => '';

  Future<void> deleteOwnedFiles(
    Iterable<String> paths, {
    required Set<String> usedPaths,
  }) async {}

  Future<void> cleanOrphans(Set<String> usedPaths) async {}
}
