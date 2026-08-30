enum SyncEntityKind {
  memoryItem('memory_item'),
  shiftSchedule('shift_schedule'),
  account('account'),
  recurrenceSeries('recurrence_series'),
  recurrenceException('recurrence_exception'),
  financeEntry('finance_entry');

  const SyncEntityKind(this.storageName);

  final String storageName;

  static SyncEntityKind fromStorageName(String value) {
    return values.firstWhere((kind) => kind.storageName == value);
  }
}

class SyncVaultProfile {
  const SyncVaultProfile({
    required this.salt,
    required this.wrappedKey,
    required this.keyVerifier,
  });

  final String salt;
  final String wrappedKey;
  final String keyVerifier;
}

class SyncRemoteEntity {
  const SyncRemoteEntity({
    required this.kind,
    required this.entityId,
    required this.updatedAt,
    this.encryptedPayload,
    this.deletedAt,
    this.revision = 0,
  });

  final SyncEntityKind kind;
  final String entityId;
  final String? encryptedPayload;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int revision;

  bool get isDeleted => deletedAt != null;

  Map<String, Object?> toRpcJson() => {
        'entity_kind': kind.storageName,
        'entity_id': entityId,
        'encrypted_payload': encryptedPayload,
        'updated_at': updatedAt.toUtc().toIso8601String(),
        'deleted_at': deletedAt?.toUtc().toIso8601String(),
      };

  factory SyncRemoteEntity.fromJson(Map<String, Object?> json) {
    return SyncRemoteEntity(
      kind: SyncEntityKind.fromStorageName(json['entity_kind'] as String),
      entityId: json['entity_id'] as String,
      encryptedPayload: json['encrypted_payload'] as String?,
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String).toLocal(),
      revision: (json['revision'] as num?)?.toInt() ?? 0,
    );
  }
}

class SyncRunResult {
  const SyncRunResult({
    required this.downloaded,
    required this.uploaded,
    required this.deleted,
  });

  final int downloaded;
  final int uploaded;
  final int deleted;
}
