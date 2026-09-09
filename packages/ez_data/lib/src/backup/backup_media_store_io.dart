import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:ez_domain/ez_domain.dart';

import '../media/media_storage_io.dart';

/// Вложения записей для резервной копии.
///
/// Ссылка в записи — имя файла, а не путь: где файл лежит и в каком он виде,
/// знает хранилище. Имя и есть то, что связывает копию с записью, поэтому при
/// восстановлении ссылки не переписываются.
Future<List<Map<String, Object?>>> collectBackupMedia(
  List<MemoryItem> items,
) async {
  final media = <Map<String, Object?>>[];
  final storage = MediaStorage();
  final seen = <String>{};

  for (final item in items) {
    for (final reference in item.mediaReferences) {
      if (MediaStorage.isExternal(reference)) continue;
      final name = MediaStorage.referenceFor(reference);
      if (!seen.add(name)) continue;
      final file = await storage.storedFile(name);
      if (file == null) continue;
      media.add({
        // Имя сохраняется тем, какое на диске: с хвостом `.ezm`, если файл
        // лежит зашифрованным, — тогда копия восстановится в том же виде.
        'fileName': p.basename(file.path),
        'bytesBase64': base64Encode(await file.readAsBytes()),
      });
    }
  }

  return media;
}

Future<List<MemoryItem>> restoreBackupMedia(
  List<MemoryItem> items,
  List<dynamic> mediaFiles,
) async {
  if (mediaFiles.isEmpty) return items;
  await MediaStorage.initialize();

  for (final entry in mediaFiles) {
    final media = Map<String, Object?>.from(entry as Map);
    final bytesBase64 = media['bytesBase64'] as String?;
    // В копиях до 1.1.0 имя лежит рядом с исходным путём; берётся имя, оно и
    // тогда было тем же, что в ссылке.
    final fileName = media['fileName'] as String? ??
        (media['originalPath'] as String?)?.split(RegExp(r'[\/]')).last;
    if (fileName == null || bytesBase64 == null) continue;

    final safeName = fileName.replaceAll(RegExp(r'[^\w.\-]+'), '_');
    await File(
      MediaStorage.resolve(
        safeName,
        encrypted: safeName.endsWith(MediaStorage.encryptedExtension),
      ),
    ).writeAsBytes(base64Decode(bytesBase64));
  }

  // Ссылки в записях не трогаются: файл вернулся под своим именем.
  return items;
}
