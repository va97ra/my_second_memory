class SecureEntityRecord {
  const SecureEntityRecord({
    required this.rowKey,
    required this.lookupKey,
    required this.encryptedPayload,
  });

  final String rowKey;
  final String lookupKey;
  final String encryptedPayload;
}

abstract interface class SecureEntityBackend {
  Future<List<SecureEntityRecord>> loadSecureEntities(String kind);

  Future<void> upsertSecureEntity({
    required String kind,
    required String rowKey,
    required String lookupKey,
    required String encryptedPayload,
  });

  Future<void> upsertSecureEntities(
    String kind,
    List<SecureEntityRecord> records,
  );

  Future<void> deleteSecureEntity(String kind, String lookupKey);

  Future<void> replaceSecureEntities(
    String kind,
    List<SecureEntityRecord> records,
  );
}
