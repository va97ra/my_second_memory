enum FinanceEntryKind { income, expense }

class FinanceEntry {
  FinanceEntry({
    required String id,
    required this.kind,
    required String amount,
    required String currencyCode,
    required String category,
    required this.occurredOn,
    required this.createdAt,
    required this.updatedAt,
    String description = '',
  })  : id = id.trim(),
        amount = _normalizedAmount(amount),
        currencyCode = currencyCode.trim().toUpperCase(),
        category = category.trim(),
        description = description.trim() {
    if (this.id.isEmpty) {
      throw const FormatException('Finance entry id must not be empty');
    }
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(this.currencyCode)) {
      throw const FormatException('Finance currency must be an ISO code');
    }
    if (this.category.isEmpty) {
      throw const FormatException('Finance category must not be empty');
    }
  }

  final String id;
  final FinanceEntryKind kind;

  /// Canonical positive decimal representation. Never stored as a double.
  final String amount;
  final String currencyCode;
  final String category;
  final String description;
  final DateTime occurredOn;
  final DateTime createdAt;
  final DateTime updatedAt;

  FinanceEntry copyWith({
    FinanceEntryKind? kind,
    String? amount,
    String? currencyCode,
    String? category,
    String? description,
    DateTime? occurredOn,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FinanceEntry(
      id: id,
      kind: kind ?? this.kind,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      category: category ?? this.category,
      description: description ?? this.description,
      occurredOn: occurredOn ?? this.occurredOn,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'kind': kind.name,
        'amount': amount,
        'currencyCode': currencyCode,
        'category': category,
        'description': description,
        'occurredOn': occurredOn.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory FinanceEntry.fromJson(Map<String, Object?> json) {
    return FinanceEntry(
      id: json['id'] as String,
      kind: FinanceEntryKind.values.byName(json['kind'] as String),
      amount: json['amount'] as String,
      currencyCode: json['currencyCode'] as String,
      category: json['category'] as String,
      description: json['description'] as String? ?? '',
      occurredOn: DateTime.parse(json['occurredOn'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

String _normalizedAmount(String value) {
  final normalized = value.trim().replaceAll(',', '.');
  final match = RegExp(r'^(?:0|[1-9]\d*)(?:\.\d+)?$').firstMatch(normalized);
  if (match == null || RegExp(r'^0(?:\.0+)?$').hasMatch(normalized)) {
    throw const FormatException('Finance amount must be positive');
  }
  var result = normalized;
  if (result.contains('.')) {
    result = result.replaceFirst(RegExp(r'0+$'), '');
    result = result.replaceFirst(RegExp(r'\.$'), '');
  }
  return result;
}
