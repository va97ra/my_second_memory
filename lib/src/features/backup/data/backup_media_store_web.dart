import '../../memory_items/domain/memory_item.dart';

Future<List<Map<String, Object?>>> collectBackupMedia(
  List<MemoryItem> items,
) async {
  return const [];
}

Future<List<MemoryItem>> restoreBackupMedia(
  List<MemoryItem> items,
  List<dynamic> mediaFiles,
) async {
  return items;
}
