import 'package:drift/native.dart';
import 'package:ezhednevnik_v2/src/data/database/app_database.dart';
import 'package:ezhednevnik_v2/src/data/database/drift_secure_entity_backend.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/data/encrypted_memory_repository.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/data/sqlite_memory_repository.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_item.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_type.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ezhednevnik_v2/src/features/notifications/data/notification_service.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/data/encrypted_recurrence_exception_repository.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/data/encrypted_recurrence_repository.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/data/sqlite_recurrence_exception_repository.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/data/sqlite_recurrence_repository.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/domain/recurrence_projection_service.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/domain/recurrence_series.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/state/recurrence_exception_controller.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/state/recurrence_series_controller.dart';
import 'package:ezhednevnik_v2/src/features/security/data/app_cipher.dart';
import 'package:ezhednevnik_v2/src/features/security/data/encrypted_json_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('PIN user: deleting one subscription occurrence persists the marker',
      () async {
    SharedPreferences.setMockInitialValues({});
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final backend = DriftSecureEntityBackend(database);
    final cipher = await AppCipher.fromPin(
      pin: '1234',
      salt: List<int>.filled(16, 7),
    );
    addTearDown(cipher.destroy);
    final store = EncryptedJsonStore(cipher: cipher);

    final memoryRepository = EncryptedMemoryRepository(
      store: store,
      plainRepository: SqliteMemoryRepository(
        database: database,
        closeDatabase: false,
      ),
      backend: backend,
    );
    final seriesRepository = EncryptedRecurrenceRepository(
      store: store,
      plainRepository: SqliteRecurrenceRepository(database),
      backend: backend,
    );
    final exceptionRepository = EncryptedRecurrenceExceptionRepository(
      store: store,
      plainRepository: SqliteRecurrenceExceptionRepository(database),
      backend: backend,
    );

    final today = dateOnly(DateTime.now());
    final memories = MemoryItemsController(memoryRepository);
    final exceptions = RecurrenceExceptionController(exceptionRepository);
    final reminders = NotificationService();
    addTearDown(reminders.dispose);
    final controller = RecurrenceSeriesController(
      seriesRepository,
      exceptions,
      memories,
      reminders,
    );
    await controller.load();

    final now = DateTime.now();
    final item = MemoryItem(
      id: 'sub-1',
      type: MemoryType.payment,
      title: 'Тест записи',
      body: 'Тест записи',
      timeMinutes: 9 * 60,
      memoryDate: today,
      createdAt: now,
      updatedAt: now,
      amountMinor: 60000,
      paymentCategory: PaymentCategory.subscription.name,
    );
    await memories.add(item);
    final series =
        await controller.setFrequency(item, RecurrenceFrequency.monthly);
    await controller.setTermMonths(series.id, 3);

    final occurrence = const RecurrenceProjectionService()
        .itemsForRange(
          start: today,
          end: today,
          series: controller.state,
          exceptions: exceptions.state,
          persistedItems: memories.state,
        )
        .single;
    await controller.deleteOccurrence(occurrence);

    final kinds = await database
        .customSelect('select kind, count(*) c from secure_entities group by kind')
        .get();
    // ignore: avoid_print
    print('secure_entities: '
        '${{for (final row in kinds) row.data['kind']: row.data['c']}}');

    expect(exceptions.state, hasLength(1),
        reason: 'controller must hold the skip marker');
    expect(
      await exceptionRepository.loadAll(),
      hasLength(1),
      reason: 'the skip marker must be readable back from storage',
    );

    final stored = await backend.loadSecureEntities(
      EncryptedRecurrenceExceptionRepository.entityKind,
    );
    expect(stored, hasLength(1),
        reason: 'the skip marker must exist as an encrypted row');
  });
}
