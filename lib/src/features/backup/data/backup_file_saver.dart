import 'backup_file_saver_stub.dart'
    if (dart.library.io) 'backup_file_saver_io.dart'
    if (dart.library.html) 'backup_file_saver_web.dart';

abstract final class BackupFileSaver {
  static Future<String?> saveToDownloads({
    required String fileName,
    required List<int> bytes,
  }) {
    return saveBackupToDownloads(fileName: fileName, bytes: bytes);
  }

  static Future<String?> saveFileToDownloads({
    required String fileName,
    required String sourcePath,
  }) {
    return saveBackupFileToDownloads(
      fileName: fileName,
      sourcePath: sourcePath,
    );
  }
}
