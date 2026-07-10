// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $MemoryItemsTable extends MemoryItems
    with TableInfo<$MemoryItemsTable, MemoryItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemoryItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
      'body', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _timeMinutesMeta =
      const VerificationMeta('timeMinutes');
  @override
  late final GeneratedColumn<int> timeMinutes = GeneratedColumn<int>(
      'time_minutes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _memoryDateMeta =
      const VerificationMeta('memoryDate');
  @override
  late final GeneratedColumn<DateTime> memoryDate = GeneratedColumn<DateTime>(
      'memory_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('active'));
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
      'priority', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _tagsJsonMeta =
      const VerificationMeta('tagsJson');
  @override
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
      'tags_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _remindAtMeta =
      const VerificationMeta('remindAt');
  @override
  late final GeneratedColumn<DateTime> remindAt = GeneratedColumn<DateTime>(
      'remind_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _repeatRuleMeta =
      const VerificationMeta('repeatRule');
  @override
  late final GeneratedColumn<String> repeatRule = GeneratedColumn<String>(
      'repeat_rule', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _projectIdMeta =
      const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
      'project_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _personIdsJsonMeta =
      const VerificationMeta('personIdsJson');
  @override
  late final GeneratedColumn<String> personIdsJson = GeneratedColumn<String>(
      'person_ids_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _placeIdMeta =
      const VerificationMeta('placeId');
  @override
  late final GeneratedColumn<String> placeId = GeneratedColumn<String>(
      'place_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _audioPathMeta =
      const VerificationMeta('audioPath');
  @override
  late final GeneratedColumn<String> audioPath = GeneratedColumn<String>(
      'audio_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _audioDurationSecondsMeta =
      const VerificationMeta('audioDurationSeconds');
  @override
  late final GeneratedColumn<int> audioDurationSeconds = GeneratedColumn<int>(
      'audio_duration_seconds', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _imagePathsJsonMeta =
      const VerificationMeta('imagePathsJson');
  @override
  late final GeneratedColumn<String> imagePathsJson = GeneratedColumn<String>(
      'image_paths_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _transcriptMeta =
      const VerificationMeta('transcript');
  @override
  late final GeneratedColumn<String> transcript = GeneratedColumn<String>(
      'transcript', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        type,
        title,
        body,
        timeMinutes,
        memoryDate,
        createdAt,
        updatedAt,
        status,
        priority,
        tagsJson,
        remindAt,
        repeatRule,
        projectId,
        personIdsJson,
        placeId,
        audioPath,
        audioDurationSeconds,
        imagePathsJson,
        transcript
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'memory_items';
  @override
  VerificationContext validateIntegrity(Insertable<MemoryItemRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
          _bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    }
    if (data.containsKey('time_minutes')) {
      context.handle(
          _timeMinutesMeta,
          timeMinutes.isAcceptableOrUnknown(
              data['time_minutes']!, _timeMinutesMeta));
    }
    if (data.containsKey('memory_date')) {
      context.handle(
          _memoryDateMeta,
          memoryDate.isAcceptableOrUnknown(
              data['memory_date']!, _memoryDateMeta));
    } else if (isInserting) {
      context.missing(_memoryDateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    }
    if (data.containsKey('tags_json')) {
      context.handle(_tagsJsonMeta,
          tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta));
    }
    if (data.containsKey('remind_at')) {
      context.handle(_remindAtMeta,
          remindAt.isAcceptableOrUnknown(data['remind_at']!, _remindAtMeta));
    }
    if (data.containsKey('repeat_rule')) {
      context.handle(
          _repeatRuleMeta,
          repeatRule.isAcceptableOrUnknown(
              data['repeat_rule']!, _repeatRuleMeta));
    }
    if (data.containsKey('project_id')) {
      context.handle(_projectIdMeta,
          projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta));
    }
    if (data.containsKey('person_ids_json')) {
      context.handle(
          _personIdsJsonMeta,
          personIdsJson.isAcceptableOrUnknown(
              data['person_ids_json']!, _personIdsJsonMeta));
    }
    if (data.containsKey('place_id')) {
      context.handle(_placeIdMeta,
          placeId.isAcceptableOrUnknown(data['place_id']!, _placeIdMeta));
    }
    if (data.containsKey('audio_path')) {
      context.handle(_audioPathMeta,
          audioPath.isAcceptableOrUnknown(data['audio_path']!, _audioPathMeta));
    }
    if (data.containsKey('audio_duration_seconds')) {
      context.handle(
          _audioDurationSecondsMeta,
          audioDurationSeconds.isAcceptableOrUnknown(
              data['audio_duration_seconds']!, _audioDurationSecondsMeta));
    }
    if (data.containsKey('image_paths_json')) {
      context.handle(
          _imagePathsJsonMeta,
          imagePathsJson.isAcceptableOrUnknown(
              data['image_paths_json']!, _imagePathsJsonMeta));
    }
    if (data.containsKey('transcript')) {
      context.handle(
          _transcriptMeta,
          transcript.isAcceptableOrUnknown(
              data['transcript']!, _transcriptMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MemoryItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemoryItemRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      body: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body'])!,
      timeMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}time_minutes']),
      memoryDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}memory_date'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}priority'])!,
      tagsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags_json'])!,
      remindAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}remind_at']),
      repeatRule: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}repeat_rule']),
      projectId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}project_id']),
      personIdsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}person_ids_json'])!,
      placeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}place_id']),
      audioPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}audio_path']),
      audioDurationSeconds: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}audio_duration_seconds']),
      imagePathsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}image_paths_json'])!,
      transcript: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}transcript']),
    );
  }

  @override
  $MemoryItemsTable createAlias(String alias) {
    return $MemoryItemsTable(attachedDatabase, alias);
  }
}

class MemoryItemRow extends DataClass implements Insertable<MemoryItemRow> {
  final String id;
  final String type;
  final String title;
  final String body;
  final int? timeMinutes;
  final DateTime memoryDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status;
  final int priority;
  final String tagsJson;
  final DateTime? remindAt;
  final String? repeatRule;
  final String? projectId;
  final String personIdsJson;
  final String? placeId;
  final String? audioPath;
  final int? audioDurationSeconds;
  final String imagePathsJson;
  final String? transcript;
  const MemoryItemRow(
      {required this.id,
      required this.type,
      required this.title,
      required this.body,
      this.timeMinutes,
      required this.memoryDate,
      required this.createdAt,
      required this.updatedAt,
      required this.status,
      required this.priority,
      required this.tagsJson,
      this.remindAt,
      this.repeatRule,
      this.projectId,
      required this.personIdsJson,
      this.placeId,
      this.audioPath,
      this.audioDurationSeconds,
      required this.imagePathsJson,
      this.transcript});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    if (!nullToAbsent || timeMinutes != null) {
      map['time_minutes'] = Variable<int>(timeMinutes);
    }
    map['memory_date'] = Variable<DateTime>(memoryDate);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['status'] = Variable<String>(status);
    map['priority'] = Variable<int>(priority);
    map['tags_json'] = Variable<String>(tagsJson);
    if (!nullToAbsent || remindAt != null) {
      map['remind_at'] = Variable<DateTime>(remindAt);
    }
    if (!nullToAbsent || repeatRule != null) {
      map['repeat_rule'] = Variable<String>(repeatRule);
    }
    if (!nullToAbsent || projectId != null) {
      map['project_id'] = Variable<String>(projectId);
    }
    map['person_ids_json'] = Variable<String>(personIdsJson);
    if (!nullToAbsent || placeId != null) {
      map['place_id'] = Variable<String>(placeId);
    }
    if (!nullToAbsent || audioPath != null) {
      map['audio_path'] = Variable<String>(audioPath);
    }
    if (!nullToAbsent || audioDurationSeconds != null) {
      map['audio_duration_seconds'] = Variable<int>(audioDurationSeconds);
    }
    map['image_paths_json'] = Variable<String>(imagePathsJson);
    if (!nullToAbsent || transcript != null) {
      map['transcript'] = Variable<String>(transcript);
    }
    return map;
  }

  MemoryItemsCompanion toCompanion(bool nullToAbsent) {
    return MemoryItemsCompanion(
      id: Value(id),
      type: Value(type),
      title: Value(title),
      body: Value(body),
      timeMinutes: timeMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(timeMinutes),
      memoryDate: Value(memoryDate),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      status: Value(status),
      priority: Value(priority),
      tagsJson: Value(tagsJson),
      remindAt: remindAt == null && nullToAbsent
          ? const Value.absent()
          : Value(remindAt),
      repeatRule: repeatRule == null && nullToAbsent
          ? const Value.absent()
          : Value(repeatRule),
      projectId: projectId == null && nullToAbsent
          ? const Value.absent()
          : Value(projectId),
      personIdsJson: Value(personIdsJson),
      placeId: placeId == null && nullToAbsent
          ? const Value.absent()
          : Value(placeId),
      audioPath: audioPath == null && nullToAbsent
          ? const Value.absent()
          : Value(audioPath),
      audioDurationSeconds: audioDurationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(audioDurationSeconds),
      imagePathsJson: Value(imagePathsJson),
      transcript: transcript == null && nullToAbsent
          ? const Value.absent()
          : Value(transcript),
    );
  }

  factory MemoryItemRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemoryItemRow(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      timeMinutes: serializer.fromJson<int?>(json['timeMinutes']),
      memoryDate: serializer.fromJson<DateTime>(json['memoryDate']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      status: serializer.fromJson<String>(json['status']),
      priority: serializer.fromJson<int>(json['priority']),
      tagsJson: serializer.fromJson<String>(json['tagsJson']),
      remindAt: serializer.fromJson<DateTime?>(json['remindAt']),
      repeatRule: serializer.fromJson<String?>(json['repeatRule']),
      projectId: serializer.fromJson<String?>(json['projectId']),
      personIdsJson: serializer.fromJson<String>(json['personIdsJson']),
      placeId: serializer.fromJson<String?>(json['placeId']),
      audioPath: serializer.fromJson<String?>(json['audioPath']),
      audioDurationSeconds:
          serializer.fromJson<int?>(json['audioDurationSeconds']),
      imagePathsJson: serializer.fromJson<String>(json['imagePathsJson']),
      transcript: serializer.fromJson<String?>(json['transcript']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'timeMinutes': serializer.toJson<int?>(timeMinutes),
      'memoryDate': serializer.toJson<DateTime>(memoryDate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'status': serializer.toJson<String>(status),
      'priority': serializer.toJson<int>(priority),
      'tagsJson': serializer.toJson<String>(tagsJson),
      'remindAt': serializer.toJson<DateTime?>(remindAt),
      'repeatRule': serializer.toJson<String?>(repeatRule),
      'projectId': serializer.toJson<String?>(projectId),
      'personIdsJson': serializer.toJson<String>(personIdsJson),
      'placeId': serializer.toJson<String?>(placeId),
      'audioPath': serializer.toJson<String?>(audioPath),
      'audioDurationSeconds': serializer.toJson<int?>(audioDurationSeconds),
      'imagePathsJson': serializer.toJson<String>(imagePathsJson),
      'transcript': serializer.toJson<String?>(transcript),
    };
  }

  MemoryItemRow copyWith(
          {String? id,
          String? type,
          String? title,
          String? body,
          Value<int?> timeMinutes = const Value.absent(),
          DateTime? memoryDate,
          DateTime? createdAt,
          DateTime? updatedAt,
          String? status,
          int? priority,
          String? tagsJson,
          Value<DateTime?> remindAt = const Value.absent(),
          Value<String?> repeatRule = const Value.absent(),
          Value<String?> projectId = const Value.absent(),
          String? personIdsJson,
          Value<String?> placeId = const Value.absent(),
          Value<String?> audioPath = const Value.absent(),
          Value<int?> audioDurationSeconds = const Value.absent(),
          String? imagePathsJson,
          Value<String?> transcript = const Value.absent()}) =>
      MemoryItemRow(
        id: id ?? this.id,
        type: type ?? this.type,
        title: title ?? this.title,
        body: body ?? this.body,
        timeMinutes: timeMinutes.present ? timeMinutes.value : this.timeMinutes,
        memoryDate: memoryDate ?? this.memoryDate,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        status: status ?? this.status,
        priority: priority ?? this.priority,
        tagsJson: tagsJson ?? this.tagsJson,
        remindAt: remindAt.present ? remindAt.value : this.remindAt,
        repeatRule: repeatRule.present ? repeatRule.value : this.repeatRule,
        projectId: projectId.present ? projectId.value : this.projectId,
        personIdsJson: personIdsJson ?? this.personIdsJson,
        placeId: placeId.present ? placeId.value : this.placeId,
        audioPath: audioPath.present ? audioPath.value : this.audioPath,
        audioDurationSeconds: audioDurationSeconds.present
            ? audioDurationSeconds.value
            : this.audioDurationSeconds,
        imagePathsJson: imagePathsJson ?? this.imagePathsJson,
        transcript: transcript.present ? transcript.value : this.transcript,
      );
  MemoryItemRow copyWithCompanion(MemoryItemsCompanion data) {
    return MemoryItemRow(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      timeMinutes:
          data.timeMinutes.present ? data.timeMinutes.value : this.timeMinutes,
      memoryDate:
          data.memoryDate.present ? data.memoryDate.value : this.memoryDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      status: data.status.present ? data.status.value : this.status,
      priority: data.priority.present ? data.priority.value : this.priority,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
      remindAt: data.remindAt.present ? data.remindAt.value : this.remindAt,
      repeatRule:
          data.repeatRule.present ? data.repeatRule.value : this.repeatRule,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      personIdsJson: data.personIdsJson.present
          ? data.personIdsJson.value
          : this.personIdsJson,
      placeId: data.placeId.present ? data.placeId.value : this.placeId,
      audioPath: data.audioPath.present ? data.audioPath.value : this.audioPath,
      audioDurationSeconds: data.audioDurationSeconds.present
          ? data.audioDurationSeconds.value
          : this.audioDurationSeconds,
      imagePathsJson: data.imagePathsJson.present
          ? data.imagePathsJson.value
          : this.imagePathsJson,
      transcript:
          data.transcript.present ? data.transcript.value : this.transcript,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemoryItemRow(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('timeMinutes: $timeMinutes, ')
          ..write('memoryDate: $memoryDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('remindAt: $remindAt, ')
          ..write('repeatRule: $repeatRule, ')
          ..write('projectId: $projectId, ')
          ..write('personIdsJson: $personIdsJson, ')
          ..write('placeId: $placeId, ')
          ..write('audioPath: $audioPath, ')
          ..write('audioDurationSeconds: $audioDurationSeconds, ')
          ..write('imagePathsJson: $imagePathsJson, ')
          ..write('transcript: $transcript')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      type,
      title,
      body,
      timeMinutes,
      memoryDate,
      createdAt,
      updatedAt,
      status,
      priority,
      tagsJson,
      remindAt,
      repeatRule,
      projectId,
      personIdsJson,
      placeId,
      audioPath,
      audioDurationSeconds,
      imagePathsJson,
      transcript);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemoryItemRow &&
          other.id == this.id &&
          other.type == this.type &&
          other.title == this.title &&
          other.body == this.body &&
          other.timeMinutes == this.timeMinutes &&
          other.memoryDate == this.memoryDate &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.status == this.status &&
          other.priority == this.priority &&
          other.tagsJson == this.tagsJson &&
          other.remindAt == this.remindAt &&
          other.repeatRule == this.repeatRule &&
          other.projectId == this.projectId &&
          other.personIdsJson == this.personIdsJson &&
          other.placeId == this.placeId &&
          other.audioPath == this.audioPath &&
          other.audioDurationSeconds == this.audioDurationSeconds &&
          other.imagePathsJson == this.imagePathsJson &&
          other.transcript == this.transcript);
}

class MemoryItemsCompanion extends UpdateCompanion<MemoryItemRow> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> title;
  final Value<String> body;
  final Value<int?> timeMinutes;
  final Value<DateTime> memoryDate;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> status;
  final Value<int> priority;
  final Value<String> tagsJson;
  final Value<DateTime?> remindAt;
  final Value<String?> repeatRule;
  final Value<String?> projectId;
  final Value<String> personIdsJson;
  final Value<String?> placeId;
  final Value<String?> audioPath;
  final Value<int?> audioDurationSeconds;
  final Value<String> imagePathsJson;
  final Value<String?> transcript;
  final Value<int> rowid;
  const MemoryItemsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.timeMinutes = const Value.absent(),
    this.memoryDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.priority = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.remindAt = const Value.absent(),
    this.repeatRule = const Value.absent(),
    this.projectId = const Value.absent(),
    this.personIdsJson = const Value.absent(),
    this.placeId = const Value.absent(),
    this.audioPath = const Value.absent(),
    this.audioDurationSeconds = const Value.absent(),
    this.imagePathsJson = const Value.absent(),
    this.transcript = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MemoryItemsCompanion.insert({
    required String id,
    required String type,
    required String title,
    this.body = const Value.absent(),
    this.timeMinutes = const Value.absent(),
    required DateTime memoryDate,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.status = const Value.absent(),
    this.priority = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.remindAt = const Value.absent(),
    this.repeatRule = const Value.absent(),
    this.projectId = const Value.absent(),
    this.personIdsJson = const Value.absent(),
    this.placeId = const Value.absent(),
    this.audioPath = const Value.absent(),
    this.audioDurationSeconds = const Value.absent(),
    this.imagePathsJson = const Value.absent(),
    this.transcript = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        type = Value(type),
        title = Value(title),
        memoryDate = Value(memoryDate),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<MemoryItemRow> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? title,
    Expression<String>? body,
    Expression<int>? timeMinutes,
    Expression<DateTime>? memoryDate,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? status,
    Expression<int>? priority,
    Expression<String>? tagsJson,
    Expression<DateTime>? remindAt,
    Expression<String>? repeatRule,
    Expression<String>? projectId,
    Expression<String>? personIdsJson,
    Expression<String>? placeId,
    Expression<String>? audioPath,
    Expression<int>? audioDurationSeconds,
    Expression<String>? imagePathsJson,
    Expression<String>? transcript,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (timeMinutes != null) 'time_minutes': timeMinutes,
      if (memoryDate != null) 'memory_date': memoryDate,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (status != null) 'status': status,
      if (priority != null) 'priority': priority,
      if (tagsJson != null) 'tags_json': tagsJson,
      if (remindAt != null) 'remind_at': remindAt,
      if (repeatRule != null) 'repeat_rule': repeatRule,
      if (projectId != null) 'project_id': projectId,
      if (personIdsJson != null) 'person_ids_json': personIdsJson,
      if (placeId != null) 'place_id': placeId,
      if (audioPath != null) 'audio_path': audioPath,
      if (audioDurationSeconds != null)
        'audio_duration_seconds': audioDurationSeconds,
      if (imagePathsJson != null) 'image_paths_json': imagePathsJson,
      if (transcript != null) 'transcript': transcript,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MemoryItemsCompanion copyWith(
      {Value<String>? id,
      Value<String>? type,
      Value<String>? title,
      Value<String>? body,
      Value<int?>? timeMinutes,
      Value<DateTime>? memoryDate,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<String>? status,
      Value<int>? priority,
      Value<String>? tagsJson,
      Value<DateTime?>? remindAt,
      Value<String?>? repeatRule,
      Value<String?>? projectId,
      Value<String>? personIdsJson,
      Value<String?>? placeId,
      Value<String?>? audioPath,
      Value<int?>? audioDurationSeconds,
      Value<String>? imagePathsJson,
      Value<String?>? transcript,
      Value<int>? rowid}) {
    return MemoryItemsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      timeMinutes: timeMinutes ?? this.timeMinutes,
      memoryDate: memoryDate ?? this.memoryDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      tagsJson: tagsJson ?? this.tagsJson,
      remindAt: remindAt ?? this.remindAt,
      repeatRule: repeatRule ?? this.repeatRule,
      projectId: projectId ?? this.projectId,
      personIdsJson: personIdsJson ?? this.personIdsJson,
      placeId: placeId ?? this.placeId,
      audioPath: audioPath ?? this.audioPath,
      audioDurationSeconds: audioDurationSeconds ?? this.audioDurationSeconds,
      imagePathsJson: imagePathsJson ?? this.imagePathsJson,
      transcript: transcript ?? this.transcript,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (timeMinutes.present) {
      map['time_minutes'] = Variable<int>(timeMinutes.value);
    }
    if (memoryDate.present) {
      map['memory_date'] = Variable<DateTime>(memoryDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
    }
    if (remindAt.present) {
      map['remind_at'] = Variable<DateTime>(remindAt.value);
    }
    if (repeatRule.present) {
      map['repeat_rule'] = Variable<String>(repeatRule.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (personIdsJson.present) {
      map['person_ids_json'] = Variable<String>(personIdsJson.value);
    }
    if (placeId.present) {
      map['place_id'] = Variable<String>(placeId.value);
    }
    if (audioPath.present) {
      map['audio_path'] = Variable<String>(audioPath.value);
    }
    if (audioDurationSeconds.present) {
      map['audio_duration_seconds'] = Variable<int>(audioDurationSeconds.value);
    }
    if (imagePathsJson.present) {
      map['image_paths_json'] = Variable<String>(imagePathsJson.value);
    }
    if (transcript.present) {
      map['transcript'] = Variable<String>(transcript.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemoryItemsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('timeMinutes: $timeMinutes, ')
          ..write('memoryDate: $memoryDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('remindAt: $remindAt, ')
          ..write('repeatRule: $repeatRule, ')
          ..write('projectId: $projectId, ')
          ..write('personIdsJson: $personIdsJson, ')
          ..write('placeId: $placeId, ')
          ..write('audioPath: $audioPath, ')
          ..write('audioDurationSeconds: $audioDurationSeconds, ')
          ..write('imagePathsJson: $imagePathsJson, ')
          ..write('transcript: $transcript, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MemoryItemsTable memoryItems = $MemoryItemsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [memoryItems];
}

typedef $$MemoryItemsTableCreateCompanionBuilder = MemoryItemsCompanion
    Function({
  required String id,
  required String type,
  required String title,
  Value<String> body,
  Value<int?> timeMinutes,
  required DateTime memoryDate,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<String> status,
  Value<int> priority,
  Value<String> tagsJson,
  Value<DateTime?> remindAt,
  Value<String?> repeatRule,
  Value<String?> projectId,
  Value<String> personIdsJson,
  Value<String?> placeId,
  Value<String?> audioPath,
  Value<int?> audioDurationSeconds,
  Value<String> imagePathsJson,
  Value<String?> transcript,
  Value<int> rowid,
});
typedef $$MemoryItemsTableUpdateCompanionBuilder = MemoryItemsCompanion
    Function({
  Value<String> id,
  Value<String> type,
  Value<String> title,
  Value<String> body,
  Value<int?> timeMinutes,
  Value<DateTime> memoryDate,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String> status,
  Value<int> priority,
  Value<String> tagsJson,
  Value<DateTime?> remindAt,
  Value<String?> repeatRule,
  Value<String?> projectId,
  Value<String> personIdsJson,
  Value<String?> placeId,
  Value<String?> audioPath,
  Value<int?> audioDurationSeconds,
  Value<String> imagePathsJson,
  Value<String?> transcript,
  Value<int> rowid,
});

class $$MemoryItemsTableFilterComposer
    extends Composer<_$AppDatabase, $MemoryItemsTable> {
  $$MemoryItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timeMinutes => $composableBuilder(
      column: $table.timeMinutes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get memoryDate => $composableBuilder(
      column: $table.memoryDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tagsJson => $composableBuilder(
      column: $table.tagsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get remindAt => $composableBuilder(
      column: $table.remindAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get repeatRule => $composableBuilder(
      column: $table.repeatRule, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get projectId => $composableBuilder(
      column: $table.projectId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get personIdsJson => $composableBuilder(
      column: $table.personIdsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get placeId => $composableBuilder(
      column: $table.placeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get audioPath => $composableBuilder(
      column: $table.audioPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get audioDurationSeconds => $composableBuilder(
      column: $table.audioDurationSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imagePathsJson => $composableBuilder(
      column: $table.imagePathsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get transcript => $composableBuilder(
      column: $table.transcript, builder: (column) => ColumnFilters(column));
}

class $$MemoryItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $MemoryItemsTable> {
  $$MemoryItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timeMinutes => $composableBuilder(
      column: $table.timeMinutes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get memoryDate => $composableBuilder(
      column: $table.memoryDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tagsJson => $composableBuilder(
      column: $table.tagsJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get remindAt => $composableBuilder(
      column: $table.remindAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get repeatRule => $composableBuilder(
      column: $table.repeatRule, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get projectId => $composableBuilder(
      column: $table.projectId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get personIdsJson => $composableBuilder(
      column: $table.personIdsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get placeId => $composableBuilder(
      column: $table.placeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get audioPath => $composableBuilder(
      column: $table.audioPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get audioDurationSeconds => $composableBuilder(
      column: $table.audioDurationSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imagePathsJson => $composableBuilder(
      column: $table.imagePathsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transcript => $composableBuilder(
      column: $table.transcript, builder: (column) => ColumnOrderings(column));
}

class $$MemoryItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MemoryItemsTable> {
  $$MemoryItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<int> get timeMinutes => $composableBuilder(
      column: $table.timeMinutes, builder: (column) => column);

  GeneratedColumn<DateTime> get memoryDate => $composableBuilder(
      column: $table.memoryDate, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get tagsJson =>
      $composableBuilder(column: $table.tagsJson, builder: (column) => column);

  GeneratedColumn<DateTime> get remindAt =>
      $composableBuilder(column: $table.remindAt, builder: (column) => column);

  GeneratedColumn<String> get repeatRule => $composableBuilder(
      column: $table.repeatRule, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get personIdsJson => $composableBuilder(
      column: $table.personIdsJson, builder: (column) => column);

  GeneratedColumn<String> get placeId =>
      $composableBuilder(column: $table.placeId, builder: (column) => column);

  GeneratedColumn<String> get audioPath =>
      $composableBuilder(column: $table.audioPath, builder: (column) => column);

  GeneratedColumn<int> get audioDurationSeconds => $composableBuilder(
      column: $table.audioDurationSeconds, builder: (column) => column);

  GeneratedColumn<String> get imagePathsJson => $composableBuilder(
      column: $table.imagePathsJson, builder: (column) => column);

  GeneratedColumn<String> get transcript => $composableBuilder(
      column: $table.transcript, builder: (column) => column);
}

class $$MemoryItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MemoryItemsTable,
    MemoryItemRow,
    $$MemoryItemsTableFilterComposer,
    $$MemoryItemsTableOrderingComposer,
    $$MemoryItemsTableAnnotationComposer,
    $$MemoryItemsTableCreateCompanionBuilder,
    $$MemoryItemsTableUpdateCompanionBuilder,
    (
      MemoryItemRow,
      BaseReferences<_$AppDatabase, $MemoryItemsTable, MemoryItemRow>
    ),
    MemoryItemRow,
    PrefetchHooks Function()> {
  $$MemoryItemsTableTableManager(_$AppDatabase db, $MemoryItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemoryItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemoryItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MemoryItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> body = const Value.absent(),
            Value<int?> timeMinutes = const Value.absent(),
            Value<DateTime> memoryDate = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> priority = const Value.absent(),
            Value<String> tagsJson = const Value.absent(),
            Value<DateTime?> remindAt = const Value.absent(),
            Value<String?> repeatRule = const Value.absent(),
            Value<String?> projectId = const Value.absent(),
            Value<String> personIdsJson = const Value.absent(),
            Value<String?> placeId = const Value.absent(),
            Value<String?> audioPath = const Value.absent(),
            Value<int?> audioDurationSeconds = const Value.absent(),
            Value<String> imagePathsJson = const Value.absent(),
            Value<String?> transcript = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MemoryItemsCompanion(
            id: id,
            type: type,
            title: title,
            body: body,
            timeMinutes: timeMinutes,
            memoryDate: memoryDate,
            createdAt: createdAt,
            updatedAt: updatedAt,
            status: status,
            priority: priority,
            tagsJson: tagsJson,
            remindAt: remindAt,
            repeatRule: repeatRule,
            projectId: projectId,
            personIdsJson: personIdsJson,
            placeId: placeId,
            audioPath: audioPath,
            audioDurationSeconds: audioDurationSeconds,
            imagePathsJson: imagePathsJson,
            transcript: transcript,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String type,
            required String title,
            Value<String> body = const Value.absent(),
            Value<int?> timeMinutes = const Value.absent(),
            required DateTime memoryDate,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<String> status = const Value.absent(),
            Value<int> priority = const Value.absent(),
            Value<String> tagsJson = const Value.absent(),
            Value<DateTime?> remindAt = const Value.absent(),
            Value<String?> repeatRule = const Value.absent(),
            Value<String?> projectId = const Value.absent(),
            Value<String> personIdsJson = const Value.absent(),
            Value<String?> placeId = const Value.absent(),
            Value<String?> audioPath = const Value.absent(),
            Value<int?> audioDurationSeconds = const Value.absent(),
            Value<String> imagePathsJson = const Value.absent(),
            Value<String?> transcript = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MemoryItemsCompanion.insert(
            id: id,
            type: type,
            title: title,
            body: body,
            timeMinutes: timeMinutes,
            memoryDate: memoryDate,
            createdAt: createdAt,
            updatedAt: updatedAt,
            status: status,
            priority: priority,
            tagsJson: tagsJson,
            remindAt: remindAt,
            repeatRule: repeatRule,
            projectId: projectId,
            personIdsJson: personIdsJson,
            placeId: placeId,
            audioPath: audioPath,
            audioDurationSeconds: audioDurationSeconds,
            imagePathsJson: imagePathsJson,
            transcript: transcript,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MemoryItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MemoryItemsTable,
    MemoryItemRow,
    $$MemoryItemsTableFilterComposer,
    $$MemoryItemsTableOrderingComposer,
    $$MemoryItemsTableAnnotationComposer,
    $$MemoryItemsTableCreateCompanionBuilder,
    $$MemoryItemsTableUpdateCompanionBuilder,
    (
      MemoryItemRow,
      BaseReferences<_$AppDatabase, $MemoryItemsTable, MemoryItemRow>
    ),
    MemoryItemRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MemoryItemsTableTableManager get memoryItems =>
      $$MemoryItemsTableTableManager(_db, _db.memoryItems);
}
