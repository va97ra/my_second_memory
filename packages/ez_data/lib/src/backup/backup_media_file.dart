import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as p;

/// Вложение, прочитанное из копии.
///
/// Разбор копии файлов не пишет: на диск они ложатся только при самом
/// восстановлении, вместе с записями, и уходят, если восстановление
/// откатилось. Иначе отменённое или сорвавшееся восстановление оставляло бы
/// чужие файлы, на которые не ссылается ничто.
final class BackupMediaFile {
  BackupMediaFile(String fileName, this.bytes)
      : fileName = fileName.replaceAll(RegExp(r'[^\w.\-]+'), '_');

  /// Имя, под которым файл лежал на диске: с хвостом `.ezm`, если он был
  /// зашифрован, — тогда он и вернётся в том же виде. Символы, которых не
  /// бывает в именах вложений, заменены: имя пришло из файла копии.
  final String fileName;
  final List<int> bytes;
}

/// Вложения из JSON-копии: имя и байты в base64.
List<BackupMediaFile> readJsonBackupMedia(List<dynamic> mediaFiles) => [
      for (final entry in mediaFiles)
        if (_jsonMediaFile(Map<String, Object?>.from(entry as Map))
            case final file?)
          file,
    ];

BackupMediaFile? _jsonMediaFile(Map<String, Object?> media) {
  final bytesBase64 = media['bytesBase64'] as String?;
  // В копиях до 1.1.0 имя лежит рядом с исходным путём; берётся имя, оно и
  // тогда было тем же, что в ссылке.
  final fileName = media['fileName'] as String? ??
      (media['originalPath'] as String?)?.split(RegExp(r'[\/]')).last;
  if (fileName == null || bytesBase64 == null) return null;
  return BackupMediaFile(fileName, base64Decode(bytesBase64));
}

/// Вложения из потоковой копии: каждый файл лежит в архиве отдельно и, если
/// копия под паролем, зашифрован своим nonce.
Future<List<BackupMediaFile>> readStreamingBackupMedia({
  required List<dynamic> mediaEntries,
  required Map<String, List<int>> archiveFiles,
  SecretKey? encryptionKey,
}) async {
  final files = <BackupMediaFile>[];
  for (final rawEntry in mediaEntries) {
    final entry = Map<String, Object?>.from(rawEntry as Map);
    final archivePath = entry['archivePath'] as String?;
    var bytes = archivePath == null ? null : archiveFiles[archivePath];
    if (archivePath == null || bytes == null) continue;
    if (encryptionKey != null) {
      bytes = await AesGcm.with256bits().decrypt(
        SecretBox(
          bytes,
          nonce: base64Decode(entry['nonce'] as String),
          mac: Mac(base64Decode(entry['mac'] as String)),
        ),
        secretKey: encryptionKey,
      );
    }
    files.add(BackupMediaFile(
      entry['fileName'] as String? ?? p.basename(archivePath),
      bytes,
    ));
  }
  return files;
}
