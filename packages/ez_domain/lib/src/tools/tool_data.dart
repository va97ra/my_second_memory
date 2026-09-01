sealed class SavedCalculationPayload {
  const SavedCalculationPayload();

  String get type;
  Map<String, Object?> toJson();

  static SavedCalculationPayload fromJson(Map<String, Object?> json) {
    return switch (json['type']) {
      'conversion' => SavedConversionPayload.fromJson(json),
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

/// Пройденная тема обучения.
///
class ToolDataSnapshot {
  const ToolDataSnapshot({
    this.calculations = const [],
  });

  final List<SavedToolCalculation> calculations;

  Map<String, Object?> toJson() => {
        'calculations': [for (final item in calculations) item.toJson()],
      };

  /// Читает снимок из резервной копии.
  ///
  /// Расчёт удалённого инструмента прочитать нечем, и такая запись
  /// пропускается: копия, снятая прежней версией, не должна из-за неё
  /// перестать восстанавливаться целиком.
  factory ToolDataSnapshot.fromJson(Map<String, Object?> json) {
    final calculations = <SavedToolCalculation>[];
    for (final raw in json['calculations'] as List<dynamic>? ?? const []) {
      try {
        calculations.add(
          SavedToolCalculation.fromJson(Map<String, Object?>.from(raw as Map)),
        );
      } on FormatException {
        continue;
      }
    }
    return ToolDataSnapshot(calculations: calculations);
  }
}
