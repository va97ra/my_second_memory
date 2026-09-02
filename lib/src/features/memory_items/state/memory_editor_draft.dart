import 'package:ez_domain/ez_domain.dart';

class MemoryEditorDraft {
  const MemoryEditorDraft({
    required this.type,
    required this.title,
    required this.body,
    required this.timeMinutes,
    required this.endMinutes,
    required this.remindAt,
    required this.reminderSoundUri,
    required this.reminderSoundName,
    required this.memoryDate,
    required this.status,
    required this.audioPath,
    required this.audioDurationSeconds,
    required this.imagePaths,
    required this.savedAt,
    required this.repeatRule,
    required this.amountMinor,
    required this.paymentCategory,
    required this.subscriptionTermMonths,
    required this.subscriptionTermDirty,
    required this.birthYear,
    required this.isUndated,
  });

  final MemoryType type;
  final String title;
  final String body;
  final int? timeMinutes;

  /// Конец записи; пусто у всего, что стоит на шкале точкой.
  final int? endMinutes;
  final DateTime? remindAt;
  final String? reminderSoundUri;
  final String? reminderSoundName;
  final DateTime memoryDate;
  final MemoryStatus status;
  final String? audioPath;
  final int? audioDurationSeconds;
  final List<String> imagePaths;
  final DateTime savedAt;
  final String? repeatRule;
  final int? amountMinor;
  final String? paymentCategory;
  final int? subscriptionTermMonths;
  final bool subscriptionTermDirty;
  final int? birthYear;
  final bool isUndated;
}
