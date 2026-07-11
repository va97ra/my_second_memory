import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../accounts/domain/account_item.dart';
import '../../memory_items/domain/memory_item.dart';
import '../../shift_schedules/domain/shift_schedule.dart';

Future<String?> createStreamingBackup({
  required String password,
  required String format,
  required int version,
  required List<MemoryItem> memoryItems,
  required List<ShiftSchedule> shiftSchedules,
  required List<AccountItem> accounts,
  String? temporaryRoot,
}) async {
  final temp = temporaryRoot == null
      ? await getTemporaryDirectory()
      : Directory(temporaryRoot);
  final token = DateTime.now().microsecondsSinceEpoch;
  final root = Directory(p.join(temp.path, 'backup_$token'));
  final staging = Directory(p.join(root.path, 'content'));
  final mediaDirectory = Directory(p.join(staging.path, 'media'));
  await mediaDirectory.create(recursive: true);
  final mediaEntries = <Map<String, String>>[];
  final seen = <String>{};
  var mediaIndex = 0;

  for (final item in memoryItems) {
    for (final sourcePath in [
      ...item.imagePaths,
      if (item.audioPath != null) item.audioPath!,
    ]) {
      if (sourcePath.startsWith('data:') ||
          sourcePath.startsWith('http') ||
          sourcePath.startsWith('blob:') ||
          !seen.add(sourcePath)) {
        continue;
      }
      final source = File(sourcePath);
      if (!await source.exists()) continue;
      final archivePath = 'media/${mediaIndex++}_${p.basename(sourcePath)}';
      await source.copy(p.join(staging.path, archivePath));
      mediaEntries.add({
        'originalPath': sourcePath,
        'archivePath': archivePath,
      });
    }
  }

  final manifest = File(p.join(staging.path, 'manifest.json'));
  await manifest.writeAsString(jsonEncode({
    'format': format,
    'version': version,
    'exportedAt': DateTime.now().toIso8601String(),
    'memoryItems': memoryItems.map((item) => item.toJson()).toList(),
    'shiftSchedules': shiftSchedules.map((item) => item.toJson()).toList(),
    'accounts': accounts.map((item) => item.toJson()).toList(),
    'mediaEntries': mediaEntries,
  }));

  final output = p.join(root.path, 'ezhednevnik_v2_backup.zip');
  await ZipFileEncoder(password: password).zipDirectory(
    staging,
    filename: output,
  );
  await staging.delete(recursive: true);
  return output;
}

Future<List<MemoryItem>> restoreStreamingMedia({
  required List<MemoryItem> items,
  required List<dynamic> mediaEntries,
  required Map<String, List<int>> archiveFiles,
}) async {
  if (mediaEntries.isEmpty) return items;
  final directory = await getApplicationDocumentsDirectory();
  final pathMap = <String, String>{};
  for (final rawEntry in mediaEntries) {
    final entry = Map<String, Object?>.from(rawEntry as Map);
    final originalPath = entry['originalPath'] as String?;
    final archivePath = entry['archivePath'] as String?;
    final bytes = archivePath == null ? null : archiveFiles[archivePath];
    if (originalPath == null || archivePath == null || bytes == null) continue;
    final safeName =
        p.basename(archivePath).replaceAll(RegExp(r'[^\w.\-]+'), '_');
    final restoredPath = p.join(
      directory.path,
      'restored_${DateTime.now().microsecondsSinceEpoch}_$safeName',
    );
    await File(restoredPath).writeAsBytes(bytes);
    pathMap[originalPath] = restoredPath;
  }
  return [
    for (final item in items)
      item.copyWith(
        imagePaths: [for (final path in item.imagePaths) pathMap[path] ?? path],
        audioPath: item.audioPath == null
            ? null
            : pathMap[item.audioPath!] ?? item.audioPath,
      ),
  ];
}

Future<void> deleteStreamingBackup(String path) async {
  final file = File(path);
  final parent = file.parent;
  if (await parent.exists()) await parent.delete(recursive: true);
}
