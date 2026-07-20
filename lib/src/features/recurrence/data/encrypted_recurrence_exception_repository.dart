import '../../security/data/encrypted_json_store.dart';
import '../../security/data/secure_entity_backend.dart';
import '../../security/data/secure_entity_codec.dart';
import '../domain/recurrence_occurrence_exception.dart';
import 'recurrence_exception_repository.dart';

class EncryptedRecurrenceExceptionRepository
    implements RecurrenceExceptionRepository {
  const EncryptedRecurrenceExceptionRepository({
    required this.store,
    required this.plainRepository,
    this.backend,
  });

  static const storageKey = 'encrypted_recurrence_exceptions_v1';
  static const entityKind = 'recurrence_exception';

  final EncryptedJsonStore store;
  final RecurrenceExceptionRepository plainRepository;
  final SecureEntityBackend? backend;

  SecureEntityCodec get _codec => SecureEntityCodec(store.cipher);

  @override
  Future<List<RecurrenceOccurrenceException>> loadAll() async {
    final secureBackend = backend;
    if (secureBackend != null) {
      var rows = await secureBackend.loadSecureEntities(entityKind);
      if (rows.isEmpty) {
        final plain = await plainRepository.loadAll();
        if (plain.isNotEmpty) {
          await replaceAll(plain);
          await plainRepository.replaceAll(const []);
          rows = await secureBackend.loadSecureEntities(entityKind);
        }
      }
      return [
        for (final row in rows)
          RecurrenceOccurrenceException.fromJson(await _codec.decode(row)),
      ];
    }
    if (await store.contains(storageKey)) {
      return (await store.readList(storageKey)).map((entry) {
        return RecurrenceOccurrenceException.fromJson(
          Map<String, Object?>.from(entry as Map),
        );
      }).toList();
    }
    final plain = await plainRepository.loadAll();
    await replaceAll(plain);
    await plainRepository.replaceAll(const []);
    return plain;
  }

  @override
  Future<void> upsert(RecurrenceOccurrenceException exception) async {
    final secureBackend = backend;
    if (secureBackend != null) {
      final record = await _codec.encode(exception.id, exception.toJson());
      await secureBackend.upsertSecureEntity(
        kind: entityKind,
        rowKey: record.rowKey,
        lookupKey: record.lookupKey,
        encryptedPayload: record.encryptedPayload,
      );
      return;
    }
    final all = {for (final item in await loadAll()) item.id: item};
    all[exception.id] = exception;
    await replaceAll(all.values.toList());
  }

  @override
  Future<void> upsertAll(
    List<RecurrenceOccurrenceException> exceptions,
  ) async {
    if (exceptions.isEmpty) return;
    final secureBackend = backend;
    if (secureBackend != null) {
      final records = await Future.wait([
        for (final item in exceptions) _codec.encode(item.id, item.toJson()),
      ]);
      await secureBackend.upsertSecureEntities(entityKind, records);
      return;
    }
    final all = {for (final item in await loadAll()) item.id: item};
    for (final exception in exceptions) {
      all[exception.id] = exception;
    }
    await replaceAll(all.values.toList());
  }

  @override
  Future<RecurrenceOccurrenceException> skip(
    String seriesId,
    DateTime occurrenceDate,
  ) async {
    final now = DateTime.now();
    final date = DateTime(
      occurrenceDate.year,
      occurrenceDate.month,
      occurrenceDate.day,
    );
    final exception = RecurrenceOccurrenceException(
      id: recurrenceExceptionId(seriesId, date),
      seriesId: seriesId,
      occurrenceDate: date,
      kind: RecurrenceOccurrenceExceptionKind.skipped,
      createdAt: now,
      updatedAt: now,
    );
    await upsert(exception);
    return exception;
  }

  @override
  Future<void> delete(String seriesId, DateTime occurrenceDate) async {
    final id = recurrenceExceptionId(seriesId, occurrenceDate);
    final secureBackend = backend;
    if (secureBackend != null) {
      await secureBackend.deleteSecureEntity(
        entityKind,
        await _codec.lookupKey(id),
      );
      return;
    }
    await replaceAll([
      for (final item in await loadAll())
        if (item.id != id) item,
    ]);
  }

  @override
  Future<void> deleteSeries(String seriesId) async {
    final all = await loadAll();
    await replaceAll([
      for (final item in all)
        if (item.seriesId != seriesId) item,
    ]);
  }

  @override
  Future<void> replaceAll(
    List<RecurrenceOccurrenceException> exceptions,
  ) async {
    final secureBackend = backend;
    if (secureBackend != null) {
      final records = await Future.wait([
        for (final item in exceptions) _codec.encode(item.id, item.toJson()),
      ]);
      await secureBackend.replaceSecureEntities(entityKind, records);
      return;
    }
    await store.writeList(
      storageKey,
      exceptions.map((item) => item.toJson()).toList(),
    );
  }

  @override
  Future<void> close() async {}
}
