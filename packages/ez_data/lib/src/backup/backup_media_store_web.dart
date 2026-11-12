import 'backup_media_file.dart';

// В вебе вложения живут строкой внутри записи и едут в копии вместе с ней:
// отдельных файлов нет ни при выгрузке, ни при восстановлении.

Future<List<Map<String, Object?>>> collectBackupMedia(
  Iterable<String> references,
) async =>
    const [];

Future<List<String>> writeBackupMedia(List<BackupMediaFile> files) async =>
    const [];

Future<void> removeBackupMedia(List<String> paths) async {}
