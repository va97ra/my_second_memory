import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../memory_items/domain/memory_item.dart';

Future<List<Map<String, Object?>>> collectBackupMedia(
  List<MemoryItem> items,
) async {
  final media = <Map<String, Object?>>[];
  final seen = <String>{};

  for (final item in items) {
    final paths = [
      ...item.imagePaths,
      if (item.audioPath != null) item.audioPath!,
    ];

    for (final path in paths) {
      if (path.startsWith('data:') ||
          path.startsWith('http') ||
          path.startsWith('blob:') ||
          !seen.add(path)) {
        continue;
      }

      final file = File(path);
      if (!await file.exists()) {
        continue;
      }

      final bytes = await file.readAsBytes();
      media.add({
        'originalPath': path,
        'fileName': p.basename(path),
        'bytesBase64': base64Encode(bytes),
      });
    }
  }

  return media;
}

Future<List<MemoryItem>> restoreBackupMedia(
  List<MemoryItem> items,
  List<dynamic> mediaFiles,
) async {
  if (mediaFiles.isEmpty) {
    return items;
  }

  final directory = await getApplicationDocumentsDirectory();
  final pathMap = <String, String>{};

  for (final entry in mediaFiles) {
    final media = Map<String, Object?>.from(entry as Map);
    final originalPath = media['originalPath'] as String?;
    final fileName = media['fileName'] as String? ?? 'media.bin';
    final bytesBase64 = media['bytesBase64'] as String?;
    if (originalPath == null || bytesBase64 == null) {
      continue;
    }

    final safeName = fileName.replaceAll(RegExp(r'[^\w.\-]+'), '_');
    final restoredPath = p.join(
      directory.path,
      'restored_${DateTime.now().microsecondsSinceEpoch}_$safeName',
    );
    await File(restoredPath).writeAsBytes(base64Decode(bytesBase64));
    pathMap[originalPath] = restoredPath;
  }

  return [
    for (final item in items)
      item.copyWith(
        imagePaths: [
          for (final path in item.imagePaths) pathMap[path] ?? path,
        ],
        audioPath: item.audioPath == null
            ? null
            : pathMap[item.audioPath!] ?? item.audioPath,
      ),
  ];
}
