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
    this.status = MemoryStatus.active,
    this.priority = 0,
    this.tags = const [],
    this.remindAt,
    this.repeatRule,
    this.projectId,
    this.personIds = const [],
    this.placeId,
    this.audioPath,
    this.audioDurationSeconds,
    this.imagePaths = const [],
    this.transcript,
  });

  final String id;
  final MemoryType type;
  final String title;
  final String body;
  final DateTime memoryDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final MemoryStatus status;
  final int priority;
  final List<String> tags;
  final DateTime? remindAt;
  final String? repeatRule;
  final String? projectId;
  final List<String> personIds;
  final String? placeId;
  final String? audioPath;
  final int? audioDurationSeconds;
  final List<String> imagePaths;
  final String? transcript;

  bool get isArchived => status == MemoryStatus.archived;

  bool get isDone => status == MemoryStatus.done;

  bool get isVoiceNote => type == MemoryType.voiceNote;

  MemoryItem copyWith({
    String? id,
    MemoryType? type,
    String? title,
    String? body,
    DateTime? memoryDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    MemoryStatus? status,
    int? priority,
    List<String>? tags,
    DateTime? remindAt,
    String? repeatRule,
    String? projectId,
    List<String>? personIds,
    String? placeId,
    String? audioPath,
    int? audioDurationSeconds,
    List<String>? imagePaths,
    String? transcript,
  }) {
    return MemoryItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      memoryDate: memoryDate ?? this.memoryDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
      remindAt: remindAt ?? this.remindAt,
      repeatRule: repeatRule ?? this.repeatRule,
      projectId: projectId ?? this.projectId,
      personIds: personIds ?? this.personIds,
      placeId: placeId ?? this.placeId,
      audioPath: audioPath ?? this.audioPath,
      audioDurationSeconds:
          audioDurationSeconds ?? this.audioDurationSeconds,
      imagePaths: imagePaths ?? this.imagePaths,
      transcript: transcript ?? this.transcript,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'body': body,
      'memoryDate': memoryDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status.name,
      'priority': priority,
      'tags': tags,
      'remindAt': remindAt?.toIso8601String(),
      'repeatRule': repeatRule,
      'projectId': projectId,
      'personIds': personIds,
      'placeId': placeId,
      'audioPath': audioPath,
      'audioDurationSeconds': audioDurationSeconds,
      'imagePaths': imagePaths,
      'transcript': transcript,
    };
  }

  factory MemoryItem.fromJson(Map<String, Object?> json) {
    return MemoryItem(
      id: json['id'] as String,
      type: MemoryType.values.byName(json['type'] as String),
      title: json['title'] as String,
      body: json['body'] as String? ?? '',
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
    );
  }
}
