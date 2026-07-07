import 'dart:convert';

import '../../memory_items/data/memory_repository.dart';
import '../../memory_items/domain/memory_item.dart';
import '../../shift_schedules/data/shift_schedule_repository.dart';
import '../../shift_schedules/domain/shift_schedule.dart';
import 'backup_media_store.dart';

class BackupService {
  const BackupService({
    required this.memoryRepository,
    required this.shiftScheduleRepository,
  });

  static const format = 'ezhednevnik_v2_backup';
  static const version = 1;

  final MemoryRepository memoryRepository;
  final ShiftScheduleRepository shiftScheduleRepository;

  Future<String> createBackupJson() async {
    final memoryItems = await memoryRepository.loadItems();
    final shiftSchedules = await shiftScheduleRepository.loadSchedules();
    final mediaFiles = await collectBackupMedia(memoryItems);

    return const JsonEncoder.withIndent('  ').convert({
      'format': format,
      'version': version,
      'exportedAt': DateTime.now().toIso8601String(),
      'memoryItems': memoryItems.map((item) => item.toJson()).toList(),
      'shiftSchedules': shiftSchedules.map((item) => item.toJson()).toList(),
      'mediaFiles': mediaFiles,
    });
  }

  Future<BackupRestoreData> parseBackupJson(String raw) async {
    final decoded = jsonDecode(raw) as Map<String, Object?>;
    if (decoded['format'] != format || decoded['version'] != version) {
      throw const FormatException('Unsupported backup file');
    }

    final memoryItems =
        (decoded['memoryItems'] as List<dynamic>? ?? const []).map((entry) {
      return MemoryItem.fromJson(Map<String, Object?>.from(entry as Map));
    }).toList();
    final restoredItems = await restoreBackupMedia(
      memoryItems,
      decoded['mediaFiles'] as List<dynamic>? ?? const [],
    );
    final shiftSchedules =
        (decoded['shiftSchedules'] as List<dynamic>? ?? const []).map((entry) {
      return ShiftSchedule.fromJson(Map<String, Object?>.from(entry as Map));
    }).toList();

    return BackupRestoreData(
      memoryItems: restoredItems,
      shiftSchedules: shiftSchedules,
    );
  }
}

class BackupRestoreData {
  const BackupRestoreData({
    required this.memoryItems,
    required this.shiftSchedules,
  });

  final List<MemoryItem> memoryItems;
  final List<ShiftSchedule> shiftSchedules;
}
