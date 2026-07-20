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
  static const VerificationMeta _reminderSoundUriMeta =
      const VerificationMeta('reminderSoundUri');
  @override
  late final GeneratedColumn<String> reminderSoundUri = GeneratedColumn<String>(
      'reminder_sound_uri', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _reminderSoundNameMeta =
      const VerificationMeta('reminderSoundName');
  @override
  late final GeneratedColumn<String> reminderSoundName =
      GeneratedColumn<String>('reminder_sound_name', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
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
  static const VerificationMeta _seriesIdMeta =
      const VerificationMeta('seriesId');
  @override
  late final GeneratedColumn<String> seriesId = GeneratedColumn<String>(
      'series_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _amountMinorMeta =
      const VerificationMeta('amountMinor');
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
      'amount_minor', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _paymentCategoryMeta =
      const VerificationMeta('paymentCategory');
  @override
  late final GeneratedColumn<String> paymentCategory = GeneratedColumn<String>(
      'payment_category', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _birthYearMeta =
      const VerificationMeta('birthYear');
  @override
  late final GeneratedColumn<int> birthYear = GeneratedColumn<int>(
      'birth_year', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _isGeneratedOccurrenceMeta =
      const VerificationMeta('isGeneratedOccurrence');
  @override
  late final GeneratedColumn<bool> isGeneratedOccurrence =
      GeneratedColumn<bool>('is_generated_occurrence', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("is_generated_occurrence" IN (0, 1))'),
          defaultValue: const Constant(false));
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
        reminderSoundUri,
        reminderSoundName,
        repeatRule,
        projectId,
        personIdsJson,
        placeId,
        audioPath,
        audioDurationSeconds,
        imagePathsJson,
        transcript,
        seriesId,
        amountMinor,
        paymentCategory,
        birthYear,
        isGeneratedOccurrence
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
    if (data.containsKey('reminder_sound_uri')) {
      context.handle(
          _reminderSoundUriMeta,
          reminderSoundUri.isAcceptableOrUnknown(
              data['reminder_sound_uri']!, _reminderSoundUriMeta));
    }
    if (data.containsKey('reminder_sound_name')) {
      context.handle(
          _reminderSoundNameMeta,
          reminderSoundName.isAcceptableOrUnknown(
              data['reminder_sound_name']!, _reminderSoundNameMeta));
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
    if (data.containsKey('series_id')) {
      context.handle(_seriesIdMeta,
          seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta));
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
          _amountMinorMeta,
          amountMinor.isAcceptableOrUnknown(
              data['amount_minor']!, _amountMinorMeta));
    }
    if (data.containsKey('payment_category')) {
      context.handle(
          _paymentCategoryMeta,
          paymentCategory.isAcceptableOrUnknown(
              data['payment_category']!, _paymentCategoryMeta));
    }
    if (data.containsKey('birth_year')) {
      context.handle(_birthYearMeta,
          birthYear.isAcceptableOrUnknown(data['birth_year']!, _birthYearMeta));
    }
    if (data.containsKey('is_generated_occurrence')) {
      context.handle(
          _isGeneratedOccurrenceMeta,
          isGeneratedOccurrence.isAcceptableOrUnknown(
              data['is_generated_occurrence']!, _isGeneratedOccurrenceMeta));
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
      reminderSoundUri: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}reminder_sound_uri']),
      reminderSoundName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}reminder_sound_name']),
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
      seriesId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}series_id']),
      amountMinor: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount_minor']),
      paymentCategory: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}payment_category']),
      birthYear: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}birth_year']),
      isGeneratedOccurrence: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}is_generated_occurrence'])!,
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
  final String? reminderSoundUri;
  final String? reminderSoundName;
  final String? repeatRule;
  final String? projectId;
  final String personIdsJson;
  final String? placeId;
  final String? audioPath;
  final int? audioDurationSeconds;
  final String imagePathsJson;
  final String? transcript;
  final String? seriesId;
  final int? amountMinor;
  final String? paymentCategory;
  final int? birthYear;
  final bool isGeneratedOccurrence;
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
      this.reminderSoundUri,
      this.reminderSoundName,
      this.repeatRule,
      this.projectId,
      required this.personIdsJson,
      this.placeId,
      this.audioPath,
      this.audioDurationSeconds,
      required this.imagePathsJson,
      this.transcript,
      this.seriesId,
      this.amountMinor,
      this.paymentCategory,
      this.birthYear,
      required this.isGeneratedOccurrence});
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
    if (!nullToAbsent || reminderSoundUri != null) {
      map['reminder_sound_uri'] = Variable<String>(reminderSoundUri);
    }
    if (!nullToAbsent || reminderSoundName != null) {
      map['reminder_sound_name'] = Variable<String>(reminderSoundName);
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
    if (!nullToAbsent || seriesId != null) {
      map['series_id'] = Variable<String>(seriesId);
    }
    if (!nullToAbsent || amountMinor != null) {
      map['amount_minor'] = Variable<int>(amountMinor);
    }
    if (!nullToAbsent || paymentCategory != null) {
      map['payment_category'] = Variable<String>(paymentCategory);
    }
    if (!nullToAbsent || birthYear != null) {
      map['birth_year'] = Variable<int>(birthYear);
    }
    map['is_generated_occurrence'] = Variable<bool>(isGeneratedOccurrence);
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
      reminderSoundUri: reminderSoundUri == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderSoundUri),
      reminderSoundName: reminderSoundName == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderSoundName),
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
      seriesId: seriesId == null && nullToAbsent
          ? const Value.absent()
          : Value(seriesId),
      amountMinor: amountMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(amountMinor),
      paymentCategory: paymentCategory == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentCategory),
      birthYear: birthYear == null && nullToAbsent
          ? const Value.absent()
          : Value(birthYear),
      isGeneratedOccurrence: Value(isGeneratedOccurrence),
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
      reminderSoundUri: serializer.fromJson<String?>(json['reminderSoundUri']),
      reminderSoundName:
          serializer.fromJson<String?>(json['reminderSoundName']),
      repeatRule: serializer.fromJson<String?>(json['repeatRule']),
      projectId: serializer.fromJson<String?>(json['projectId']),
      personIdsJson: serializer.fromJson<String>(json['personIdsJson']),
      placeId: serializer.fromJson<String?>(json['placeId']),
      audioPath: serializer.fromJson<String?>(json['audioPath']),
      audioDurationSeconds:
          serializer.fromJson<int?>(json['audioDurationSeconds']),
      imagePathsJson: serializer.fromJson<String>(json['imagePathsJson']),
      transcript: serializer.fromJson<String?>(json['transcript']),
      seriesId: serializer.fromJson<String?>(json['seriesId']),
      amountMinor: serializer.fromJson<int?>(json['amountMinor']),
      paymentCategory: serializer.fromJson<String?>(json['paymentCategory']),
      birthYear: serializer.fromJson<int?>(json['birthYear']),
      isGeneratedOccurrence:
          serializer.fromJson<bool>(json['isGeneratedOccurrence']),
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
      'reminderSoundUri': serializer.toJson<String?>(reminderSoundUri),
      'reminderSoundName': serializer.toJson<String?>(reminderSoundName),
      'repeatRule': serializer.toJson<String?>(repeatRule),
      'projectId': serializer.toJson<String?>(projectId),
      'personIdsJson': serializer.toJson<String>(personIdsJson),
      'placeId': serializer.toJson<String?>(placeId),
      'audioPath': serializer.toJson<String?>(audioPath),
      'audioDurationSeconds': serializer.toJson<int?>(audioDurationSeconds),
      'imagePathsJson': serializer.toJson<String>(imagePathsJson),
      'transcript': serializer.toJson<String?>(transcript),
      'seriesId': serializer.toJson<String?>(seriesId),
      'amountMinor': serializer.toJson<int?>(amountMinor),
      'paymentCategory': serializer.toJson<String?>(paymentCategory),
      'birthYear': serializer.toJson<int?>(birthYear),
      'isGeneratedOccurrence': serializer.toJson<bool>(isGeneratedOccurrence),
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
          Value<String?> reminderSoundUri = const Value.absent(),
          Value<String?> reminderSoundName = const Value.absent(),
          Value<String?> repeatRule = const Value.absent(),
          Value<String?> projectId = const Value.absent(),
          String? personIdsJson,
          Value<String?> placeId = const Value.absent(),
          Value<String?> audioPath = const Value.absent(),
          Value<int?> audioDurationSeconds = const Value.absent(),
          String? imagePathsJson,
          Value<String?> transcript = const Value.absent(),
          Value<String?> seriesId = const Value.absent(),
          Value<int?> amountMinor = const Value.absent(),
          Value<String?> paymentCategory = const Value.absent(),
          Value<int?> birthYear = const Value.absent(),
          bool? isGeneratedOccurrence}) =>
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
        reminderSoundUri: reminderSoundUri.present
            ? reminderSoundUri.value
            : this.reminderSoundUri,
        reminderSoundName: reminderSoundName.present
            ? reminderSoundName.value
            : this.reminderSoundName,
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
        seriesId: seriesId.present ? seriesId.value : this.seriesId,
        amountMinor: amountMinor.present ? amountMinor.value : this.amountMinor,
        paymentCategory: paymentCategory.present
            ? paymentCategory.value
            : this.paymentCategory,
        birthYear: birthYear.present ? birthYear.value : this.birthYear,
        isGeneratedOccurrence:
            isGeneratedOccurrence ?? this.isGeneratedOccurrence,
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
      reminderSoundUri: data.reminderSoundUri.present
          ? data.reminderSoundUri.value
          : this.reminderSoundUri,
      reminderSoundName: data.reminderSoundName.present
          ? data.reminderSoundName.value
          : this.reminderSoundName,
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
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      amountMinor:
          data.amountMinor.present ? data.amountMinor.value : this.amountMinor,
      paymentCategory: data.paymentCategory.present
          ? data.paymentCategory.value
          : this.paymentCategory,
      birthYear: data.birthYear.present ? data.birthYear.value : this.birthYear,
      isGeneratedOccurrence: data.isGeneratedOccurrence.present
          ? data.isGeneratedOccurrence.value
          : this.isGeneratedOccurrence,
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
          ..write('reminderSoundUri: $reminderSoundUri, ')
          ..write('reminderSoundName: $reminderSoundName, ')
          ..write('repeatRule: $repeatRule, ')
          ..write('projectId: $projectId, ')
          ..write('personIdsJson: $personIdsJson, ')
          ..write('placeId: $placeId, ')
          ..write('audioPath: $audioPath, ')
          ..write('audioDurationSeconds: $audioDurationSeconds, ')
          ..write('imagePathsJson: $imagePathsJson, ')
          ..write('transcript: $transcript, ')
          ..write('seriesId: $seriesId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('paymentCategory: $paymentCategory, ')
          ..write('birthYear: $birthYear, ')
          ..write('isGeneratedOccurrence: $isGeneratedOccurrence')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
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
        reminderSoundUri,
        reminderSoundName,
        repeatRule,
        projectId,
        personIdsJson,
        placeId,
        audioPath,
        audioDurationSeconds,
        imagePathsJson,
        transcript,
        seriesId,
        amountMinor,
        paymentCategory,
        birthYear,
        isGeneratedOccurrence
      ]);
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
          other.reminderSoundUri == this.reminderSoundUri &&
          other.reminderSoundName == this.reminderSoundName &&
          other.repeatRule == this.repeatRule &&
          other.projectId == this.projectId &&
          other.personIdsJson == this.personIdsJson &&
          other.placeId == this.placeId &&
          other.audioPath == this.audioPath &&
          other.audioDurationSeconds == this.audioDurationSeconds &&
          other.imagePathsJson == this.imagePathsJson &&
          other.transcript == this.transcript &&
          other.seriesId == this.seriesId &&
          other.amountMinor == this.amountMinor &&
          other.paymentCategory == this.paymentCategory &&
          other.birthYear == this.birthYear &&
          other.isGeneratedOccurrence == this.isGeneratedOccurrence);
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
  final Value<String?> reminderSoundUri;
  final Value<String?> reminderSoundName;
  final Value<String?> repeatRule;
  final Value<String?> projectId;
  final Value<String> personIdsJson;
  final Value<String?> placeId;
  final Value<String?> audioPath;
  final Value<int?> audioDurationSeconds;
  final Value<String> imagePathsJson;
  final Value<String?> transcript;
  final Value<String?> seriesId;
  final Value<int?> amountMinor;
  final Value<String?> paymentCategory;
  final Value<int?> birthYear;
  final Value<bool> isGeneratedOccurrence;
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
    this.reminderSoundUri = const Value.absent(),
    this.reminderSoundName = const Value.absent(),
    this.repeatRule = const Value.absent(),
    this.projectId = const Value.absent(),
    this.personIdsJson = const Value.absent(),
    this.placeId = const Value.absent(),
    this.audioPath = const Value.absent(),
    this.audioDurationSeconds = const Value.absent(),
    this.imagePathsJson = const Value.absent(),
    this.transcript = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.paymentCategory = const Value.absent(),
    this.birthYear = const Value.absent(),
    this.isGeneratedOccurrence = const Value.absent(),
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
    this.reminderSoundUri = const Value.absent(),
    this.reminderSoundName = const Value.absent(),
    this.repeatRule = const Value.absent(),
    this.projectId = const Value.absent(),
    this.personIdsJson = const Value.absent(),
    this.placeId = const Value.absent(),
    this.audioPath = const Value.absent(),
    this.audioDurationSeconds = const Value.absent(),
    this.imagePathsJson = const Value.absent(),
    this.transcript = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.paymentCategory = const Value.absent(),
    this.birthYear = const Value.absent(),
    this.isGeneratedOccurrence = const Value.absent(),
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
    Expression<String>? reminderSoundUri,
    Expression<String>? reminderSoundName,
    Expression<String>? repeatRule,
    Expression<String>? projectId,
    Expression<String>? personIdsJson,
    Expression<String>? placeId,
    Expression<String>? audioPath,
    Expression<int>? audioDurationSeconds,
    Expression<String>? imagePathsJson,
    Expression<String>? transcript,
    Expression<String>? seriesId,
    Expression<int>? amountMinor,
    Expression<String>? paymentCategory,
    Expression<int>? birthYear,
    Expression<bool>? isGeneratedOccurrence,
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
      if (reminderSoundUri != null) 'reminder_sound_uri': reminderSoundUri,
      if (reminderSoundName != null) 'reminder_sound_name': reminderSoundName,
      if (repeatRule != null) 'repeat_rule': repeatRule,
      if (projectId != null) 'project_id': projectId,
      if (personIdsJson != null) 'person_ids_json': personIdsJson,
      if (placeId != null) 'place_id': placeId,
      if (audioPath != null) 'audio_path': audioPath,
      if (audioDurationSeconds != null)
        'audio_duration_seconds': audioDurationSeconds,
      if (imagePathsJson != null) 'image_paths_json': imagePathsJson,
      if (transcript != null) 'transcript': transcript,
      if (seriesId != null) 'series_id': seriesId,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (paymentCategory != null) 'payment_category': paymentCategory,
      if (birthYear != null) 'birth_year': birthYear,
      if (isGeneratedOccurrence != null)
        'is_generated_occurrence': isGeneratedOccurrence,
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
      Value<String?>? reminderSoundUri,
      Value<String?>? reminderSoundName,
      Value<String?>? repeatRule,
      Value<String?>? projectId,
      Value<String>? personIdsJson,
      Value<String?>? placeId,
      Value<String?>? audioPath,
      Value<int?>? audioDurationSeconds,
      Value<String>? imagePathsJson,
      Value<String?>? transcript,
      Value<String?>? seriesId,
      Value<int?>? amountMinor,
      Value<String?>? paymentCategory,
      Value<int?>? birthYear,
      Value<bool>? isGeneratedOccurrence,
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
      reminderSoundUri: reminderSoundUri ?? this.reminderSoundUri,
      reminderSoundName: reminderSoundName ?? this.reminderSoundName,
      repeatRule: repeatRule ?? this.repeatRule,
      projectId: projectId ?? this.projectId,
      personIdsJson: personIdsJson ?? this.personIdsJson,
      placeId: placeId ?? this.placeId,
      audioPath: audioPath ?? this.audioPath,
      audioDurationSeconds: audioDurationSeconds ?? this.audioDurationSeconds,
      imagePathsJson: imagePathsJson ?? this.imagePathsJson,
      transcript: transcript ?? this.transcript,
      seriesId: seriesId ?? this.seriesId,
      amountMinor: amountMinor ?? this.amountMinor,
      paymentCategory: paymentCategory ?? this.paymentCategory,
      birthYear: birthYear ?? this.birthYear,
      isGeneratedOccurrence:
          isGeneratedOccurrence ?? this.isGeneratedOccurrence,
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
    if (reminderSoundUri.present) {
      map['reminder_sound_uri'] = Variable<String>(reminderSoundUri.value);
    }
    if (reminderSoundName.present) {
      map['reminder_sound_name'] = Variable<String>(reminderSoundName.value);
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
    if (seriesId.present) {
      map['series_id'] = Variable<String>(seriesId.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (paymentCategory.present) {
      map['payment_category'] = Variable<String>(paymentCategory.value);
    }
    if (birthYear.present) {
      map['birth_year'] = Variable<int>(birthYear.value);
    }
    if (isGeneratedOccurrence.present) {
      map['is_generated_occurrence'] =
          Variable<bool>(isGeneratedOccurrence.value);
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
          ..write('reminderSoundUri: $reminderSoundUri, ')
          ..write('reminderSoundName: $reminderSoundName, ')
          ..write('repeatRule: $repeatRule, ')
          ..write('projectId: $projectId, ')
          ..write('personIdsJson: $personIdsJson, ')
          ..write('placeId: $placeId, ')
          ..write('audioPath: $audioPath, ')
          ..write('audioDurationSeconds: $audioDurationSeconds, ')
          ..write('imagePathsJson: $imagePathsJson, ')
          ..write('transcript: $transcript, ')
          ..write('seriesId: $seriesId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('paymentCategory: $paymentCategory, ')
          ..write('birthYear: $birthYear, ')
          ..write('isGeneratedOccurrence: $isGeneratedOccurrence, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecurrenceSeriesRowsTable extends RecurrenceSeriesRows
    with TableInfo<$RecurrenceSeriesRowsTable, RecurrenceSeriesRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurrenceSeriesRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _frequencyMeta =
      const VerificationMeta('frequency');
  @override
  late final GeneratedColumn<String> frequency = GeneratedColumn<String>(
      'frequency', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _templateJsonMeta =
      const VerificationMeta('templateJson');
  @override
  late final GeneratedColumn<String> templateJson = GeneratedColumn<String>(
      'template_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startDateMeta =
      const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
      'start_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _originItemIdMeta =
      const VerificationMeta('originItemId');
  @override
  late final GeneratedColumn<String> originItemId = GeneratedColumn<String>(
      'origin_item_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isEnabledMeta =
      const VerificationMeta('isEnabled');
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
      'is_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_enabled" IN (0, 1))'),
      defaultValue: const Constant(true));
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
  static const VerificationMeta _generatedThroughMeta =
      const VerificationMeta('generatedThrough');
  @override
  late final GeneratedColumn<DateTime> generatedThrough =
      GeneratedColumn<DateTime>('generated_through', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        frequency,
        templateJson,
        startDate,
        originItemId,
        isEnabled,
        createdAt,
        updatedAt,
        generatedThrough
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurrence_series_rows';
  @override
  VerificationContext validateIntegrity(
      Insertable<RecurrenceSeriesRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('frequency')) {
      context.handle(_frequencyMeta,
          frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta));
    } else if (isInserting) {
      context.missing(_frequencyMeta);
    }
    if (data.containsKey('template_json')) {
      context.handle(
          _templateJsonMeta,
          templateJson.isAcceptableOrUnknown(
              data['template_json']!, _templateJsonMeta));
    } else if (isInserting) {
      context.missing(_templateJsonMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta,
          startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('origin_item_id')) {
      context.handle(
          _originItemIdMeta,
          originItemId.isAcceptableOrUnknown(
              data['origin_item_id']!, _originItemIdMeta));
    } else if (isInserting) {
      context.missing(_originItemIdMeta);
    }
    if (data.containsKey('is_enabled')) {
      context.handle(_isEnabledMeta,
          isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta));
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
    if (data.containsKey('generated_through')) {
      context.handle(
          _generatedThroughMeta,
          generatedThrough.isAcceptableOrUnknown(
              data['generated_through']!, _generatedThroughMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecurrenceSeriesRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecurrenceSeriesRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      frequency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}frequency'])!,
      templateJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}template_json'])!,
      startDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_date'])!,
      originItemId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}origin_item_id'])!,
      isEnabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_enabled'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      generatedThrough: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}generated_through']),
    );
  }

  @override
  $RecurrenceSeriesRowsTable createAlias(String alias) {
    return $RecurrenceSeriesRowsTable(attachedDatabase, alias);
  }
}

class RecurrenceSeriesRow extends DataClass
    implements Insertable<RecurrenceSeriesRow> {
  final String id;
  final String frequency;
  final String templateJson;
  final DateTime startDate;
  final String originItemId;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? generatedThrough;
  const RecurrenceSeriesRow(
      {required this.id,
      required this.frequency,
      required this.templateJson,
      required this.startDate,
      required this.originItemId,
      required this.isEnabled,
      required this.createdAt,
      required this.updatedAt,
      this.generatedThrough});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['frequency'] = Variable<String>(frequency);
    map['template_json'] = Variable<String>(templateJson);
    map['start_date'] = Variable<DateTime>(startDate);
    map['origin_item_id'] = Variable<String>(originItemId);
    map['is_enabled'] = Variable<bool>(isEnabled);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || generatedThrough != null) {
      map['generated_through'] = Variable<DateTime>(generatedThrough);
    }
    return map;
  }

  RecurrenceSeriesRowsCompanion toCompanion(bool nullToAbsent) {
    return RecurrenceSeriesRowsCompanion(
      id: Value(id),
      frequency: Value(frequency),
      templateJson: Value(templateJson),
      startDate: Value(startDate),
      originItemId: Value(originItemId),
      isEnabled: Value(isEnabled),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      generatedThrough: generatedThrough == null && nullToAbsent
          ? const Value.absent()
          : Value(generatedThrough),
    );
  }

  factory RecurrenceSeriesRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecurrenceSeriesRow(
      id: serializer.fromJson<String>(json['id']),
      frequency: serializer.fromJson<String>(json['frequency']),
      templateJson: serializer.fromJson<String>(json['templateJson']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      originItemId: serializer.fromJson<String>(json['originItemId']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      generatedThrough:
          serializer.fromJson<DateTime?>(json['generatedThrough']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'frequency': serializer.toJson<String>(frequency),
      'templateJson': serializer.toJson<String>(templateJson),
      'startDate': serializer.toJson<DateTime>(startDate),
      'originItemId': serializer.toJson<String>(originItemId),
      'isEnabled': serializer.toJson<bool>(isEnabled),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'generatedThrough': serializer.toJson<DateTime?>(generatedThrough),
    };
  }

  RecurrenceSeriesRow copyWith(
          {String? id,
          String? frequency,
          String? templateJson,
          DateTime? startDate,
          String? originItemId,
          bool? isEnabled,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> generatedThrough = const Value.absent()}) =>
      RecurrenceSeriesRow(
        id: id ?? this.id,
        frequency: frequency ?? this.frequency,
        templateJson: templateJson ?? this.templateJson,
        startDate: startDate ?? this.startDate,
        originItemId: originItemId ?? this.originItemId,
        isEnabled: isEnabled ?? this.isEnabled,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        generatedThrough: generatedThrough.present
            ? generatedThrough.value
            : this.generatedThrough,
      );
  RecurrenceSeriesRow copyWithCompanion(RecurrenceSeriesRowsCompanion data) {
    return RecurrenceSeriesRow(
      id: data.id.present ? data.id.value : this.id,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      templateJson: data.templateJson.present
          ? data.templateJson.value
          : this.templateJson,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      originItemId: data.originItemId.present
          ? data.originItemId.value
          : this.originItemId,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      generatedThrough: data.generatedThrough.present
          ? data.generatedThrough.value
          : this.generatedThrough,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecurrenceSeriesRow(')
          ..write('id: $id, ')
          ..write('frequency: $frequency, ')
          ..write('templateJson: $templateJson, ')
          ..write('startDate: $startDate, ')
          ..write('originItemId: $originItemId, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('generatedThrough: $generatedThrough')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, frequency, templateJson, startDate,
      originItemId, isEnabled, createdAt, updatedAt, generatedThrough);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecurrenceSeriesRow &&
          other.id == this.id &&
          other.frequency == this.frequency &&
          other.templateJson == this.templateJson &&
          other.startDate == this.startDate &&
          other.originItemId == this.originItemId &&
          other.isEnabled == this.isEnabled &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.generatedThrough == this.generatedThrough);
}

class RecurrenceSeriesRowsCompanion
    extends UpdateCompanion<RecurrenceSeriesRow> {
  final Value<String> id;
  final Value<String> frequency;
  final Value<String> templateJson;
  final Value<DateTime> startDate;
  final Value<String> originItemId;
  final Value<bool> isEnabled;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> generatedThrough;
  final Value<int> rowid;
  const RecurrenceSeriesRowsCompanion({
    this.id = const Value.absent(),
    this.frequency = const Value.absent(),
    this.templateJson = const Value.absent(),
    this.startDate = const Value.absent(),
    this.originItemId = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.generatedThrough = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecurrenceSeriesRowsCompanion.insert({
    required String id,
    required String frequency,
    required String templateJson,
    required DateTime startDate,
    required String originItemId,
    this.isEnabled = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.generatedThrough = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        frequency = Value(frequency),
        templateJson = Value(templateJson),
        startDate = Value(startDate),
        originItemId = Value(originItemId),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<RecurrenceSeriesRow> custom({
    Expression<String>? id,
    Expression<String>? frequency,
    Expression<String>? templateJson,
    Expression<DateTime>? startDate,
    Expression<String>? originItemId,
    Expression<bool>? isEnabled,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? generatedThrough,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (frequency != null) 'frequency': frequency,
      if (templateJson != null) 'template_json': templateJson,
      if (startDate != null) 'start_date': startDate,
      if (originItemId != null) 'origin_item_id': originItemId,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (generatedThrough != null) 'generated_through': generatedThrough,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecurrenceSeriesRowsCompanion copyWith(
      {Value<String>? id,
      Value<String>? frequency,
      Value<String>? templateJson,
      Value<DateTime>? startDate,
      Value<String>? originItemId,
      Value<bool>? isEnabled,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? generatedThrough,
      Value<int>? rowid}) {
    return RecurrenceSeriesRowsCompanion(
      id: id ?? this.id,
      frequency: frequency ?? this.frequency,
      templateJson: templateJson ?? this.templateJson,
      startDate: startDate ?? this.startDate,
      originItemId: originItemId ?? this.originItemId,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      generatedThrough: generatedThrough ?? this.generatedThrough,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(frequency.value);
    }
    if (templateJson.present) {
      map['template_json'] = Variable<String>(templateJson.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (originItemId.present) {
      map['origin_item_id'] = Variable<String>(originItemId.value);
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (generatedThrough.present) {
      map['generated_through'] = Variable<DateTime>(generatedThrough.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurrenceSeriesRowsCompanion(')
          ..write('id: $id, ')
          ..write('frequency: $frequency, ')
          ..write('templateJson: $templateJson, ')
          ..write('startDate: $startDate, ')
          ..write('originItemId: $originItemId, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('generatedThrough: $generatedThrough, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SecureEntitiesTable extends SecureEntities
    with TableInfo<$SecureEntitiesTable, SecureEntityRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SecureEntitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _rowKeyMeta = const VerificationMeta('rowKey');
  @override
  late final GeneratedColumn<String> rowKey = GeneratedColumn<String>(
      'row_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lookupKeyMeta =
      const VerificationMeta('lookupKey');
  @override
  late final GeneratedColumn<String> lookupKey = GeneratedColumn<String>(
      'lookup_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _encryptedPayloadMeta =
      const VerificationMeta('encryptedPayload');
  @override
  late final GeneratedColumn<String> encryptedPayload = GeneratedColumn<String>(
      'encrypted_payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [kind, rowKey, lookupKey, encryptedPayload];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'secure_entities';
  @override
  VerificationContext validateIntegrity(Insertable<SecureEntityRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('row_key')) {
      context.handle(_rowKeyMeta,
          rowKey.isAcceptableOrUnknown(data['row_key']!, _rowKeyMeta));
    } else if (isInserting) {
      context.missing(_rowKeyMeta);
    }
    if (data.containsKey('lookup_key')) {
      context.handle(_lookupKeyMeta,
          lookupKey.isAcceptableOrUnknown(data['lookup_key']!, _lookupKeyMeta));
    } else if (isInserting) {
      context.missing(_lookupKeyMeta);
    }
    if (data.containsKey('encrypted_payload')) {
      context.handle(
          _encryptedPayloadMeta,
          encryptedPayload.isAcceptableOrUnknown(
              data['encrypted_payload']!, _encryptedPayloadMeta));
    } else if (isInserting) {
      context.missing(_encryptedPayloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rowKey};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {kind, lookupKey},
      ];
  @override
  SecureEntityRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SecureEntityRow(
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      rowKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}row_key'])!,
      lookupKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lookup_key'])!,
      encryptedPayload: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}encrypted_payload'])!,
    );
  }

  @override
  $SecureEntitiesTable createAlias(String alias) {
    return $SecureEntitiesTable(attachedDatabase, alias);
  }
}

class SecureEntityRow extends DataClass implements Insertable<SecureEntityRow> {
  final String kind;
  final String rowKey;
  final String lookupKey;
  final String encryptedPayload;
  const SecureEntityRow(
      {required this.kind,
      required this.rowKey,
      required this.lookupKey,
      required this.encryptedPayload});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['kind'] = Variable<String>(kind);
    map['row_key'] = Variable<String>(rowKey);
    map['lookup_key'] = Variable<String>(lookupKey);
    map['encrypted_payload'] = Variable<String>(encryptedPayload);
    return map;
  }

  SecureEntitiesCompanion toCompanion(bool nullToAbsent) {
    return SecureEntitiesCompanion(
      kind: Value(kind),
      rowKey: Value(rowKey),
      lookupKey: Value(lookupKey),
      encryptedPayload: Value(encryptedPayload),
    );
  }

  factory SecureEntityRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SecureEntityRow(
      kind: serializer.fromJson<String>(json['kind']),
      rowKey: serializer.fromJson<String>(json['rowKey']),
      lookupKey: serializer.fromJson<String>(json['lookupKey']),
      encryptedPayload: serializer.fromJson<String>(json['encryptedPayload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kind': serializer.toJson<String>(kind),
      'rowKey': serializer.toJson<String>(rowKey),
      'lookupKey': serializer.toJson<String>(lookupKey),
      'encryptedPayload': serializer.toJson<String>(encryptedPayload),
    };
  }

  SecureEntityRow copyWith(
          {String? kind,
          String? rowKey,
          String? lookupKey,
          String? encryptedPayload}) =>
      SecureEntityRow(
        kind: kind ?? this.kind,
        rowKey: rowKey ?? this.rowKey,
        lookupKey: lookupKey ?? this.lookupKey,
        encryptedPayload: encryptedPayload ?? this.encryptedPayload,
      );
  SecureEntityRow copyWithCompanion(SecureEntitiesCompanion data) {
    return SecureEntityRow(
      kind: data.kind.present ? data.kind.value : this.kind,
      rowKey: data.rowKey.present ? data.rowKey.value : this.rowKey,
      lookupKey: data.lookupKey.present ? data.lookupKey.value : this.lookupKey,
      encryptedPayload: data.encryptedPayload.present
          ? data.encryptedPayload.value
          : this.encryptedPayload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SecureEntityRow(')
          ..write('kind: $kind, ')
          ..write('rowKey: $rowKey, ')
          ..write('lookupKey: $lookupKey, ')
          ..write('encryptedPayload: $encryptedPayload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(kind, rowKey, lookupKey, encryptedPayload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SecureEntityRow &&
          other.kind == this.kind &&
          other.rowKey == this.rowKey &&
          other.lookupKey == this.lookupKey &&
          other.encryptedPayload == this.encryptedPayload);
}

class SecureEntitiesCompanion extends UpdateCompanion<SecureEntityRow> {
  final Value<String> kind;
  final Value<String> rowKey;
  final Value<String> lookupKey;
  final Value<String> encryptedPayload;
  final Value<int> rowid;
  const SecureEntitiesCompanion({
    this.kind = const Value.absent(),
    this.rowKey = const Value.absent(),
    this.lookupKey = const Value.absent(),
    this.encryptedPayload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SecureEntitiesCompanion.insert({
    required String kind,
    required String rowKey,
    required String lookupKey,
    required String encryptedPayload,
    this.rowid = const Value.absent(),
  })  : kind = Value(kind),
        rowKey = Value(rowKey),
        lookupKey = Value(lookupKey),
        encryptedPayload = Value(encryptedPayload);
  static Insertable<SecureEntityRow> custom({
    Expression<String>? kind,
    Expression<String>? rowKey,
    Expression<String>? lookupKey,
    Expression<String>? encryptedPayload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (kind != null) 'kind': kind,
      if (rowKey != null) 'row_key': rowKey,
      if (lookupKey != null) 'lookup_key': lookupKey,
      if (encryptedPayload != null) 'encrypted_payload': encryptedPayload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SecureEntitiesCompanion copyWith(
      {Value<String>? kind,
      Value<String>? rowKey,
      Value<String>? lookupKey,
      Value<String>? encryptedPayload,
      Value<int>? rowid}) {
    return SecureEntitiesCompanion(
      kind: kind ?? this.kind,
      rowKey: rowKey ?? this.rowKey,
      lookupKey: lookupKey ?? this.lookupKey,
      encryptedPayload: encryptedPayload ?? this.encryptedPayload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (rowKey.present) {
      map['row_key'] = Variable<String>(rowKey.value);
    }
    if (lookupKey.present) {
      map['lookup_key'] = Variable<String>(lookupKey.value);
    }
    if (encryptedPayload.present) {
      map['encrypted_payload'] = Variable<String>(encryptedPayload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SecureEntitiesCompanion(')
          ..write('kind: $kind, ')
          ..write('rowKey: $rowKey, ')
          ..write('lookupKey: $lookupKey, ')
          ..write('encryptedPayload: $encryptedPayload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MemoryItemsTable memoryItems = $MemoryItemsTable(this);
  late final $RecurrenceSeriesRowsTable recurrenceSeriesRows =
      $RecurrenceSeriesRowsTable(this);
  late final $SecureEntitiesTable secureEntities = $SecureEntitiesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [memoryItems, recurrenceSeriesRows, secureEntities];
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
  Value<String?> reminderSoundUri,
  Value<String?> reminderSoundName,
  Value<String?> repeatRule,
  Value<String?> projectId,
  Value<String> personIdsJson,
  Value<String?> placeId,
  Value<String?> audioPath,
  Value<int?> audioDurationSeconds,
  Value<String> imagePathsJson,
  Value<String?> transcript,
  Value<String?> seriesId,
  Value<int?> amountMinor,
  Value<String?> paymentCategory,
  Value<int?> birthYear,
  Value<bool> isGeneratedOccurrence,
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
  Value<String?> reminderSoundUri,
  Value<String?> reminderSoundName,
  Value<String?> repeatRule,
  Value<String?> projectId,
  Value<String> personIdsJson,
  Value<String?> placeId,
  Value<String?> audioPath,
  Value<int?> audioDurationSeconds,
  Value<String> imagePathsJson,
  Value<String?> transcript,
  Value<String?> seriesId,
  Value<int?> amountMinor,
  Value<String?> paymentCategory,
  Value<int?> birthYear,
  Value<bool> isGeneratedOccurrence,
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

  ColumnFilters<String> get reminderSoundUri => $composableBuilder(
      column: $table.reminderSoundUri,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reminderSoundName => $composableBuilder(
      column: $table.reminderSoundName,
      builder: (column) => ColumnFilters(column));

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

  ColumnFilters<String> get seriesId => $composableBuilder(
      column: $table.seriesId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amountMinor => $composableBuilder(
      column: $table.amountMinor, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paymentCategory => $composableBuilder(
      column: $table.paymentCategory,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get birthYear => $composableBuilder(
      column: $table.birthYear, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isGeneratedOccurrence => $composableBuilder(
      column: $table.isGeneratedOccurrence,
      builder: (column) => ColumnFilters(column));
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

  ColumnOrderings<String> get reminderSoundUri => $composableBuilder(
      column: $table.reminderSoundUri,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reminderSoundName => $composableBuilder(
      column: $table.reminderSoundName,
      builder: (column) => ColumnOrderings(column));

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

  ColumnOrderings<String> get seriesId => $composableBuilder(
      column: $table.seriesId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amountMinor => $composableBuilder(
      column: $table.amountMinor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paymentCategory => $composableBuilder(
      column: $table.paymentCategory,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get birthYear => $composableBuilder(
      column: $table.birthYear, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isGeneratedOccurrence => $composableBuilder(
      column: $table.isGeneratedOccurrence,
      builder: (column) => ColumnOrderings(column));
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

  GeneratedColumn<String> get reminderSoundUri => $composableBuilder(
      column: $table.reminderSoundUri, builder: (column) => column);

  GeneratedColumn<String> get reminderSoundName => $composableBuilder(
      column: $table.reminderSoundName, builder: (column) => column);

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

  GeneratedColumn<String> get seriesId =>
      $composableBuilder(column: $table.seriesId, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
      column: $table.amountMinor, builder: (column) => column);

  GeneratedColumn<String> get paymentCategory => $composableBuilder(
      column: $table.paymentCategory, builder: (column) => column);

  GeneratedColumn<int> get birthYear =>
      $composableBuilder(column: $table.birthYear, builder: (column) => column);

  GeneratedColumn<bool> get isGeneratedOccurrence => $composableBuilder(
      column: $table.isGeneratedOccurrence, builder: (column) => column);
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
            Value<String?> reminderSoundUri = const Value.absent(),
            Value<String?> reminderSoundName = const Value.absent(),
            Value<String?> repeatRule = const Value.absent(),
            Value<String?> projectId = const Value.absent(),
            Value<String> personIdsJson = const Value.absent(),
            Value<String?> placeId = const Value.absent(),
            Value<String?> audioPath = const Value.absent(),
            Value<int?> audioDurationSeconds = const Value.absent(),
            Value<String> imagePathsJson = const Value.absent(),
            Value<String?> transcript = const Value.absent(),
            Value<String?> seriesId = const Value.absent(),
            Value<int?> amountMinor = const Value.absent(),
            Value<String?> paymentCategory = const Value.absent(),
            Value<int?> birthYear = const Value.absent(),
            Value<bool> isGeneratedOccurrence = const Value.absent(),
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
            reminderSoundUri: reminderSoundUri,
            reminderSoundName: reminderSoundName,
            repeatRule: repeatRule,
            projectId: projectId,
            personIdsJson: personIdsJson,
            placeId: placeId,
            audioPath: audioPath,
            audioDurationSeconds: audioDurationSeconds,
            imagePathsJson: imagePathsJson,
            transcript: transcript,
            seriesId: seriesId,
            amountMinor: amountMinor,
            paymentCategory: paymentCategory,
            birthYear: birthYear,
            isGeneratedOccurrence: isGeneratedOccurrence,
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
            Value<String?> reminderSoundUri = const Value.absent(),
            Value<String?> reminderSoundName = const Value.absent(),
            Value<String?> repeatRule = const Value.absent(),
            Value<String?> projectId = const Value.absent(),
            Value<String> personIdsJson = const Value.absent(),
            Value<String?> placeId = const Value.absent(),
            Value<String?> audioPath = const Value.absent(),
            Value<int?> audioDurationSeconds = const Value.absent(),
            Value<String> imagePathsJson = const Value.absent(),
            Value<String?> transcript = const Value.absent(),
            Value<String?> seriesId = const Value.absent(),
            Value<int?> amountMinor = const Value.absent(),
            Value<String?> paymentCategory = const Value.absent(),
            Value<int?> birthYear = const Value.absent(),
            Value<bool> isGeneratedOccurrence = const Value.absent(),
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
            reminderSoundUri: reminderSoundUri,
            reminderSoundName: reminderSoundName,
            repeatRule: repeatRule,
            projectId: projectId,
            personIdsJson: personIdsJson,
            placeId: placeId,
            audioPath: audioPath,
            audioDurationSeconds: audioDurationSeconds,
            imagePathsJson: imagePathsJson,
            transcript: transcript,
            seriesId: seriesId,
            amountMinor: amountMinor,
            paymentCategory: paymentCategory,
            birthYear: birthYear,
            isGeneratedOccurrence: isGeneratedOccurrence,
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
typedef $$RecurrenceSeriesRowsTableCreateCompanionBuilder
    = RecurrenceSeriesRowsCompanion Function({
  required String id,
  required String frequency,
  required String templateJson,
  required DateTime startDate,
  required String originItemId,
  Value<bool> isEnabled,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> generatedThrough,
  Value<int> rowid,
});
typedef $$RecurrenceSeriesRowsTableUpdateCompanionBuilder
    = RecurrenceSeriesRowsCompanion Function({
  Value<String> id,
  Value<String> frequency,
  Value<String> templateJson,
  Value<DateTime> startDate,
  Value<String> originItemId,
  Value<bool> isEnabled,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> generatedThrough,
  Value<int> rowid,
});

class $$RecurrenceSeriesRowsTableFilterComposer
    extends Composer<_$AppDatabase, $RecurrenceSeriesRowsTable> {
  $$RecurrenceSeriesRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get frequency => $composableBuilder(
      column: $table.frequency, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get templateJson => $composableBuilder(
      column: $table.templateJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get originItemId => $composableBuilder(
      column: $table.originItemId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isEnabled => $composableBuilder(
      column: $table.isEnabled, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get generatedThrough => $composableBuilder(
      column: $table.generatedThrough,
      builder: (column) => ColumnFilters(column));
}

class $$RecurrenceSeriesRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecurrenceSeriesRowsTable> {
  $$RecurrenceSeriesRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get frequency => $composableBuilder(
      column: $table.frequency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get templateJson => $composableBuilder(
      column: $table.templateJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get originItemId => $composableBuilder(
      column: $table.originItemId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
      column: $table.isEnabled, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get generatedThrough => $composableBuilder(
      column: $table.generatedThrough,
      builder: (column) => ColumnOrderings(column));
}

class $$RecurrenceSeriesRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecurrenceSeriesRowsTable> {
  $$RecurrenceSeriesRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<String> get templateJson => $composableBuilder(
      column: $table.templateJson, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get originItemId => $composableBuilder(
      column: $table.originItemId, builder: (column) => column);

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get generatedThrough => $composableBuilder(
      column: $table.generatedThrough, builder: (column) => column);
}

class $$RecurrenceSeriesRowsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RecurrenceSeriesRowsTable,
    RecurrenceSeriesRow,
    $$RecurrenceSeriesRowsTableFilterComposer,
    $$RecurrenceSeriesRowsTableOrderingComposer,
    $$RecurrenceSeriesRowsTableAnnotationComposer,
    $$RecurrenceSeriesRowsTableCreateCompanionBuilder,
    $$RecurrenceSeriesRowsTableUpdateCompanionBuilder,
    (
      RecurrenceSeriesRow,
      BaseReferences<_$AppDatabase, $RecurrenceSeriesRowsTable,
          RecurrenceSeriesRow>
    ),
    RecurrenceSeriesRow,
    PrefetchHooks Function()> {
  $$RecurrenceSeriesRowsTableTableManager(
      _$AppDatabase db, $RecurrenceSeriesRowsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecurrenceSeriesRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecurrenceSeriesRowsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecurrenceSeriesRowsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> frequency = const Value.absent(),
            Value<String> templateJson = const Value.absent(),
            Value<DateTime> startDate = const Value.absent(),
            Value<String> originItemId = const Value.absent(),
            Value<bool> isEnabled = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> generatedThrough = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecurrenceSeriesRowsCompanion(
            id: id,
            frequency: frequency,
            templateJson: templateJson,
            startDate: startDate,
            originItemId: originItemId,
            isEnabled: isEnabled,
            createdAt: createdAt,
            updatedAt: updatedAt,
            generatedThrough: generatedThrough,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String frequency,
            required String templateJson,
            required DateTime startDate,
            required String originItemId,
            Value<bool> isEnabled = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> generatedThrough = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecurrenceSeriesRowsCompanion.insert(
            id: id,
            frequency: frequency,
            templateJson: templateJson,
            startDate: startDate,
            originItemId: originItemId,
            isEnabled: isEnabled,
            createdAt: createdAt,
            updatedAt: updatedAt,
            generatedThrough: generatedThrough,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RecurrenceSeriesRowsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $RecurrenceSeriesRowsTable,
        RecurrenceSeriesRow,
        $$RecurrenceSeriesRowsTableFilterComposer,
        $$RecurrenceSeriesRowsTableOrderingComposer,
        $$RecurrenceSeriesRowsTableAnnotationComposer,
        $$RecurrenceSeriesRowsTableCreateCompanionBuilder,
        $$RecurrenceSeriesRowsTableUpdateCompanionBuilder,
        (
          RecurrenceSeriesRow,
          BaseReferences<_$AppDatabase, $RecurrenceSeriesRowsTable,
              RecurrenceSeriesRow>
        ),
        RecurrenceSeriesRow,
        PrefetchHooks Function()>;
typedef $$SecureEntitiesTableCreateCompanionBuilder = SecureEntitiesCompanion
    Function({
  required String kind,
  required String rowKey,
  required String lookupKey,
  required String encryptedPayload,
  Value<int> rowid,
});
typedef $$SecureEntitiesTableUpdateCompanionBuilder = SecureEntitiesCompanion
    Function({
  Value<String> kind,
  Value<String> rowKey,
  Value<String> lookupKey,
  Value<String> encryptedPayload,
  Value<int> rowid,
});

class $$SecureEntitiesTableFilterComposer
    extends Composer<_$AppDatabase, $SecureEntitiesTable> {
  $$SecureEntitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rowKey => $composableBuilder(
      column: $table.rowKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lookupKey => $composableBuilder(
      column: $table.lookupKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get encryptedPayload => $composableBuilder(
      column: $table.encryptedPayload,
      builder: (column) => ColumnFilters(column));
}

class $$SecureEntitiesTableOrderingComposer
    extends Composer<_$AppDatabase, $SecureEntitiesTable> {
  $$SecureEntitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rowKey => $composableBuilder(
      column: $table.rowKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lookupKey => $composableBuilder(
      column: $table.lookupKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get encryptedPayload => $composableBuilder(
      column: $table.encryptedPayload,
      builder: (column) => ColumnOrderings(column));
}

class $$SecureEntitiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SecureEntitiesTable> {
  $$SecureEntitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get rowKey =>
      $composableBuilder(column: $table.rowKey, builder: (column) => column);

  GeneratedColumn<String> get lookupKey =>
      $composableBuilder(column: $table.lookupKey, builder: (column) => column);

  GeneratedColumn<String> get encryptedPayload => $composableBuilder(
      column: $table.encryptedPayload, builder: (column) => column);
}

class $$SecureEntitiesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SecureEntitiesTable,
    SecureEntityRow,
    $$SecureEntitiesTableFilterComposer,
    $$SecureEntitiesTableOrderingComposer,
    $$SecureEntitiesTableAnnotationComposer,
    $$SecureEntitiesTableCreateCompanionBuilder,
    $$SecureEntitiesTableUpdateCompanionBuilder,
    (
      SecureEntityRow,
      BaseReferences<_$AppDatabase, $SecureEntitiesTable, SecureEntityRow>
    ),
    SecureEntityRow,
    PrefetchHooks Function()> {
  $$SecureEntitiesTableTableManager(
      _$AppDatabase db, $SecureEntitiesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SecureEntitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SecureEntitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SecureEntitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> kind = const Value.absent(),
            Value<String> rowKey = const Value.absent(),
            Value<String> lookupKey = const Value.absent(),
            Value<String> encryptedPayload = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SecureEntitiesCompanion(
            kind: kind,
            rowKey: rowKey,
            lookupKey: lookupKey,
            encryptedPayload: encryptedPayload,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String kind,
            required String rowKey,
            required String lookupKey,
            required String encryptedPayload,
            Value<int> rowid = const Value.absent(),
          }) =>
              SecureEntitiesCompanion.insert(
            kind: kind,
            rowKey: rowKey,
            lookupKey: lookupKey,
            encryptedPayload: encryptedPayload,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SecureEntitiesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SecureEntitiesTable,
    SecureEntityRow,
    $$SecureEntitiesTableFilterComposer,
    $$SecureEntitiesTableOrderingComposer,
    $$SecureEntitiesTableAnnotationComposer,
    $$SecureEntitiesTableCreateCompanionBuilder,
    $$SecureEntitiesTableUpdateCompanionBuilder,
    (
      SecureEntityRow,
      BaseReferences<_$AppDatabase, $SecureEntitiesTable, SecureEntityRow>
    ),
    SecureEntityRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MemoryItemsTableTableManager get memoryItems =>
      $$MemoryItemsTableTableManager(_db, _db.memoryItems);
  $$RecurrenceSeriesRowsTableTableManager get recurrenceSeriesRows =>
      $$RecurrenceSeriesRowsTableTableManager(_db, _db.recurrenceSeriesRows);
  $$SecureEntitiesTableTableManager get secureEntities =>
      $$SecureEntitiesTableTableManager(_db, _db.secureEntities);
}
