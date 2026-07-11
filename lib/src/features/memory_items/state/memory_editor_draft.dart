import '../domain/memory_status.dart';
import '../domain/memory_type.dart';

class MemoryEditorDraft {
  const MemoryEditorDraft({
    required this.type,
    required this.title,
    required this.body,
    required this.timeMinutes,
    required this.remindAt,
    required this.reminderSoundUri,
    required this.reminderSoundName,
    required this.memoryDate,
    required this.status,
    required this.audioPath,
    required this.audioDurationSeconds,
    required this.imagePaths,
    required this.savedAt,
  });

  final MemoryType type;
  final String title;
  final String body;
  final int? timeMinutes;
  final DateTime? remindAt;
  final String? reminderSoundUri;
  final String? reminderSoundName;
  final DateTime memoryDate;
  final MemoryStatus status;
  final String? audioPath;
  final int? audioDurationSeconds;
  final List<String> imagePaths;
  final DateTime savedAt;
}
