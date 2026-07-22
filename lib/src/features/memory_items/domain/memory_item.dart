import 'memory_status.dart';
import 'memory_type.dart';

class MemoryItem {
  const MemoryItem({
    required this.id,
    required this.type,
    required this.title,
    required this.memoryDate,
    required this.createdAt,
    required this.updatedAt,
    this.body = '',
    this.timeMinutes,
    this.status = MemoryStatus.active,
    this.priority = 0,
    this.tags = const [],
    this.remindAt,
    this.reminderSoundUri,
    this.reminderSoundName,
    this.repeatRule,
    this.projectId,
    this.personIds = const [],
    this.placeId,
    this.audioPath,
    this.audioDurationSeconds,
    this.imagePaths = const [],
    this.transcript,
    this.seriesId,
    this.amountMinor,
    this.paymentCategory,
    this.birthYear,
    this.isGeneratedOccurrence = false,
  });

  final String id;
  final MemoryType type;
  final String title;
  final String body;
  final int? timeMinutes;
  final DateTime memoryDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final MemoryStatus status;
  final int priority;
  final List<String> tags;
  final DateTime? remindAt;
  final String? reminderSoundUri;
  final String? reminderSoundName;
  final String? repeatRule;
  final String? projectId;
  final List<String> personIds;
  final String? placeId;
  final String? audioPath;
  final int? audioDurationSeconds;
  final List<String> imagePaths;
  final String? transcript;
  final String? seriesId;
  final int? amountMinor;
  final String? paymentCategory;
  final int? birthYear;
  final bool isGeneratedOccurrence;

  bool get isArchived => status == MemoryStatus.archived;

  bool get isDone => status == MemoryStatus.done;

  bool get isVoiceNote => type == MemoryType.voiceNote;

  MemoryItem copyWith({
    String? id,
    MemoryType? type,
    String? title,
    String? body,
    int? timeMinutes,
    bool clearTime = false,
    DateTime? memoryDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    MemoryStatus? status,
    int? priority,
    List<String>? tags,
    DateTime? remindAt,
    bool clearReminder = false,
    String? reminderSoundUri,
    String? reminderSoundName,
    bool clearReminderSound = false,
    String? repeatRule,
    bool clearRepeatRule = false,
    String? projectId,
    List<String>? personIds,
    String? placeId,
    String? audioPath,
    int? audioDurationSeconds,
    bool clearAudio = false,
    List<String>? imagePaths,
    String? transcript,
    String? seriesId,
    bool clearSeries = false,
    int? amountMinor,
    bool clearAmount = false,
    String? paymentCategory,
    bool clearPaymentCategory = false,
    int? birthYear,
    bool clearBirthYear = false,
    bool? isGeneratedOccurrence,
  }) {
    return MemoryItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      timeMinutes: clearTime ? null : timeMinutes ?? this.timeMinutes,
      memoryDate: memoryDate ?? this.memoryDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
      remindAt: clearReminder ? null : remindAt ?? this.remindAt,
      reminderSoundUri:
          clearReminderSound ? null : reminderSoundUri ?? this.reminderSoundUri,
      reminderSoundName: clearReminderSound
          ? null
          : reminderSoundName ?? this.reminderSoundName,
      repeatRule: clearRepeatRule ? null : repeatRule ?? this.repeatRule,
      projectId: projectId ?? this.projectId,
      personIds: personIds ?? this.personIds,
      placeId: placeId ?? this.placeId,
      audioPath: clearAudio ? null : audioPath ?? this.audioPath,
      audioDurationSeconds:
          clearAudio ? null : audioDurationSeconds ?? this.audioDurationSeconds,
      imagePaths: imagePaths ?? this.imagePaths,
      transcript: transcript ?? this.transcript,
      seriesId: clearSeries ? null : seriesId ?? this.seriesId,
      amountMinor: clearAmount ? null : amountMinor ?? this.amountMinor,
      paymentCategory:
          clearPaymentCategory ? null : paymentCategory ?? this.paymentCategory,
      birthYear: clearBirthYear ? null : birthYear ?? this.birthYear,
      isGeneratedOccurrence:
          isGeneratedOccurrence ?? this.isGeneratedOccurrence,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'body': body,
      'timeMinutes': timeMinutes,
      'memoryDate': memoryDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status.name,
      'priority': priority,
      'tags': tags,
      'remindAt': remindAt?.toIso8601String(),
      'reminderSoundUri': reminderSoundUri,
      'reminderSoundName': reminderSoundName,
      'repeatRule': repeatRule,
      'projectId': projectId,
      'personIds': personIds,
      'placeId': placeId,
      'audioPath': audioPath,
      'audioDurationSeconds': audioDurationSeconds,
      'imagePaths': imagePaths,
      'transcript': transcript,
      'seriesId': seriesId,
      'amountMinor': amountMinor,
      'paymentCategory': paymentCategory,
      'birthYear': birthYear,
      'isGeneratedOccurrence': isGeneratedOccurrence,
    };
  }

  factory MemoryItem.fromJson(Map<String, Object?> json) {
    return MemoryItem(
      id: json['id'] as String,
      type: MemoryType.values.byName(json['type'] as String),
      title: json['title'] as String,
      body: json['body'] as String? ?? '',
      timeMinutes: json['timeMinutes'] as int?,
      memoryDate: DateTime.parse(json['memoryDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      status: MemoryStatus.values.byName(json['status'] as String),
      priority: json['priority'] as int? ?? 0,
      tags: (json['tags'] as List<dynamic>? ?? const []).cast<String>(),
      remindAt: switch (json['remindAt']) {
        final String value => DateTime.parse(value),
        _ => null,
      },
      reminderSoundUri: json['reminderSoundUri'] as String?,
      reminderSoundName: json['reminderSoundName'] as String?,
      repeatRule: json['repeatRule'] as String?,
      projectId: json['projectId'] as String?,
      personIds:
          (json['personIds'] as List<dynamic>? ?? const []).cast<String>(),
      placeId: json['placeId'] as String?,
      audioPath: json['audioPath'] as String?,
      audioDurationSeconds: json['audioDurationSeconds'] as int?,
      imagePaths:
          (json['imagePaths'] as List<dynamic>? ?? const []).cast<String>(),
      transcript: json['transcript'] as String?,
      seriesId: json['seriesId'] as String?,
      amountMinor: json['amountMinor'] as int?,
      paymentCategory: json['paymentCategory'] as String?,
      birthYear: json['birthYear'] as int?,
      isGeneratedOccurrence: json['isGeneratedOccurrence'] as bool? ?? false,
    );
  }
}
