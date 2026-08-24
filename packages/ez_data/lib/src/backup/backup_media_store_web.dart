import 'package:ez_domain/ez_domain.dart';

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
