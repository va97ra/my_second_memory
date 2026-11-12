import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../media/media_storage_io.dart';
import 'backup_media_file.dart';

/// Вложения для JSON-копии.
///
/// [references] — все ссылки данных, см. `mediaReferencesOf`. Ссылка — имя
/// файла, а не путь: где файл лежит и в каком он виде, знает хранилище. Имя и
/// есть то, что связывает копию с записью, поэтому при восстановлении ссылки
/// не переписываются.
Future<List<Map<String, Object?>>> collectBackupMedia(
  Iterable<String> references,
) async {
  final media = <Map<String, Object?>>[];
  final storage = MediaStorage();
  for (final name in MediaStorage.storedNames(references)) {
    final file = await storage.storedFile(name);
    if (file == null) continue;
    media.add({
      // Имя сохраняется тем, какое на диске: с хвостом `.ezm`, если файл
      // лежит зашифрованным, — тогда копия восстановится в том же виде.
      'fileName': p.basename(file.path),
      'bytesBase64': base64Encode(await file.readAsBytes()),
    });
  }
  return media;
}

/// Кладёт вложения копии на диск и возвращает пути тех, которых здесь не
/// было: только их и можно убрать, если восстановление откатится. Файл,
/// лежавший раньше, принадлежит прежним данным, и откат его не трогает.
///
/// Если запись сорвалась на середине, уже положенные новые файлы убираются
/// здесь же: вызвавший получит ошибку, а не список.
Future<List<String>> writeBackupMedia(List<BackupMediaFile> files) async {
  if (files.isEmpty) return const [];
  await MediaStorage.initialize();
  final added = <String>[];
  try {
    for (final media in files) {
      final file = File(
        MediaStorage.resolve(
          media.fileName,
          encrypted: media.fileName.endsWith(MediaStorage.encryptedExtension),
        ),
      );
      final existed = await file.exists();
      await file.writeAsBytes(media.bytes, flush: true);
      if (!existed) added.add(file.path);
    }
  } on Object {
    await removeBackupMedia(added);
    rethrow;
  }
  return added;
}

/// Убирает файлы, положенные восстановлением, которое откатилось.
Future<void> removeBackupMedia(List<String> paths) async {
  for (final path in paths) {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}
