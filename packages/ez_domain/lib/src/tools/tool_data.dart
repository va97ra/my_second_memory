sealed class SavedCalculationPayload {
  const SavedCalculationPayload();

  String get type;
  Map<String, Object?> toJson();

  static SavedCalculationPayload fromJson(Map<String, Object?> json) {
    return switch (json['type']) {
      'conversion' => SavedConversionPayload.fromJson(json),
      'engineering' => SavedEngineeringPayload.fromJson(json),
      _ => throw FormatException('Unknown saved calculation type'),
    };
  }
}

class SavedConversionPayload extends SavedCalculationPayload {
  const SavedConversionPayload({
    required this.category,
    required this.fromUnit,
    required this.toUnit,
    required this.value,
  });

  final String category;
  final String fromUnit;
  final String toUnit;
  final double value;

  @override
  String get type => 'conversion';

  @override
  Map<String, Object?> toJson() => {
        'type': type,
        'category': category,
        'fromUnit': fromUnit,
        'toUnit': toUnit,
        'value': value,
      };

  factory SavedConversionPayload.fromJson(Map<String, Object?> json) {
    return SavedConversionPayload(
      category: json['category'] as String,
      fromUnit: json['fromUnit'] as String,
      toUnit: json['toUnit'] as String,
      value: (json['value'] as num).toDouble(),
    );
  }
}

class SavedEngineeringPayload extends SavedCalculationPayload {
  SavedEngineeringPayload({
    required this.discipline,
    required this.calculator,
    required this.values,
  }) {
    _validateEngineeringPayload(discipline, calculator, values);
  }

  final String discipline;
  final String calculator;
  final Map<String, double> values;

  @override
  String get type => 'engineering';

  @override
  Map<String, Object?> toJson() => {
        'type': type,
        'discipline': discipline,
        'calculator': calculator,
        'values': values,
      };

  factory SavedEngineeringPayload.fromJson(Map<String, Object?> json) {
    return SavedEngineeringPayload(
      discipline: json['discipline'] as String,
      calculator: json['calculator'] as String,
      values: {
        for (final entry
            in Map<String, Object?>.from(json['values'] as Map).entries)
          entry.key: (entry.value as num).toDouble(),
      },
    );
  }
}

const _engineeringSchemas = <String, Set<String>>{
  'electrical:power': {
    'voltageV',
    'currentA',
    'powerFactor',
    'efficiency',
    'threePhase',
  },
  'electrical:voltageDrop': {
    'voltageV',
    'currentA',
    'powerFactor',
    'lengthM',
    'sectionMm2',
    'threePhase',
    'copper',
  },
  'plumbing:flow': {'flowLMin', 'diameterMm', 'targetVelocityMs'},
  'plumbing:pipeVolume': {'flowLMin', 'diameterMm', 'lengthM'},
  'plumbing:pressureLoss': {
    'flowLMin',
    'diameterMm',
    'lengthM',
    'headM',
    'roughnessMm',
  },
  'ventilation:duct': {
    'flowM3h',
    'widthMm',
    'heightMm',
    'targetVelocityMs',
  },
  'ventilation:airExchange': {
    'lengthM',
    'widthM',
    'heightM',
    'airChangesPerHour',
  },
};

void _validateEngineeringPayload(
  String discipline,
  String calculator,
  Map<String, double> values,
) {
  if (values.values.any((value) => !value.isFinite)) {
    throw const FormatException('Engineering inputs must be finite');
  }
  if (discipline == 'electrical' && calculator == 'phaseBalance') {
    if (values.isEmpty ||
        values.keys.any((key) => !RegExp(r'^load\d+$').hasMatch(key))) {
      throw const FormatException('Invalid phase balance inputs');
    }
    return;
  }
  final expected = _engineeringSchemas['$discipline:$calculator'];
  if (expected == null ||
      expected.length != values.length ||
      !expected.every(values.containsKey)) {
    throw FormatException('Invalid inputs for $discipline:$calculator');
  }
}

class SavedToolCalculation {
  const SavedToolCalculation({
    required this.id,
    required this.name,
    required this.payload,
    required this.createdAt,
    required this.updatedAt,
    this.version = 1,
  });

  final String id;
  final String name;
  final SavedCalculationPayload payload;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'payload': payload.toJson(),
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'version': version,
      };

  SavedToolCalculation copyWith({
    String? name,
    SavedCalculationPayload? payload,
    DateTime? updatedAt,
  }) {
    return SavedToolCalculation(
      id: id,
      name: name ?? this.name,
      payload: payload ?? this.payload,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version,
    );
  }

  factory SavedToolCalculation.fromJson(Map<String, Object?> json) {
    return SavedToolCalculation(
      id: json['id'] as String,
      name: json['name'] as String,
      payload: SavedCalculationPayload.fromJson(
        Map<String, Object?>.from(json['payload'] as Map),
      ),
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toLocal(),
      version: json['version'] as int? ?? 1,
    );
  }
}

class ReferenceBookmark {
  const ReferenceBookmark({
    required this.entryId,
    required this.updatedAt,
    this.note = '',
  });

  final String entryId;
  final String note;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => {
        'entryId': entryId,
        'note': note,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  ReferenceBookmark copyWith({String? note, DateTime? updatedAt}) {
    return ReferenceBookmark(
      entryId: entryId,
      note: note ?? this.note,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ReferenceBookmark.fromJson(Map<String, Object?> json) {
    return ReferenceBookmark(
      entryId: json['entryId'] as String,
      note: json['note'] as String? ?? '',
      updatedAt: DateTime.parse(json['updatedAt'] as String).toLocal(),
    );
  }
}

/// Пройденная тема обучения.
///
/// Запись на каждую тему, а не список в одной записи: два устройства,
/// прошедшие разные темы, при слиянии дают объединение, а не спор о том,
/// чей список новее.
class LearningRecord {
  const LearningRecord({required this.topicId, required this.updatedAt});

  final String topicId;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => {
        'topicId': topicId,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  LearningRecord copyWith({DateTime? updatedAt}) => LearningRecord(
        topicId: topicId,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  factory LearningRecord.fromJson(Map<String, Object?> json) =>
      LearningRecord(
        topicId: json['topicId'] as String,
        updatedAt: DateTime.parse(json['updatedAt'] as String).toLocal(),
      );
}

class ToolDataSnapshot {
  const ToolDataSnapshot({
    this.calculations = const [],
    this.bookmarks = const [],
    this.learning = const [],
  });

  final List<SavedToolCalculation> calculations;
  final List<LearningRecord> learning;
  final List<ReferenceBookmark> bookmarks;

  Map<String, Object?> toJson() => {
        'calculations': [for (final item in calculations) item.toJson()],
        'bookmarks': [for (final item in bookmarks) item.toJson()],
      };

  factory ToolDataSnapshot.fromJson(Map<String, Object?> json) {
    return ToolDataSnapshot(
      calculations: [
        for (final raw in json['calculations'] as List<dynamic>? ?? const [])
          SavedToolCalculation.fromJson(
            Map<String, Object?>.from(raw as Map),
          ),
      ],
      bookmarks: [
        for (final raw in json['bookmarks'] as List<dynamic>? ?? const [])
          ReferenceBookmark.fromJson(Map<String, Object?>.from(raw as Map)),
      ],
    );
  }
}
