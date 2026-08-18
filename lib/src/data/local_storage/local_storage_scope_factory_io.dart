import '../../features/memory_items/data/memory_repository.dart';
import '../../features/memory_items/data/sqlite_memory_repository.dart';
import '../../features/recurrence/data/recurrence_exception_repository.dart';
import '../../features/recurrence/data/recurrence_repository.dart';
import '../../features/recurrence/data/sqlite_recurrence_exception_repository.dart';
import '../../features/recurrence/data/sqlite_recurrence_repository.dart';
import '../../features/security/data/secure_entity_backend.dart';
import '../database/app_database.dart';
import '../database/drift_secure_entity_backend.dart';
import 'local_storage_scope.dart';

LocalStorageScope createLocalStorageScope() => IoLocalStorageScope();

class IoLocalStorageScope implements LocalStorageScope {
  IoLocalStorageScope({AppDatabase? database})
      : _database = database ?? AppDatabase() {
    memoryRepository = SqliteMemoryRepository(
      database: _database,
      closeDatabase: false,
    );
    recurrenceRepository = SqliteRecurrenceRepository(_database, false);
    recurrenceExceptionRepository =
        SqliteRecurrenceExceptionRepository(_database, false);
    secureEntityBackend = DriftSecureEntityBackend(_database);
  }

  final AppDatabase _database;
  bool _closed = false;

  @override
  late final MemoryRepository memoryRepository;

  @override
  late final RecurrenceRepository recurrenceRepository;

  @override
  late final RecurrenceExceptionRepository recurrenceExceptionRepository;

  @override
  late final SecureEntityBackend secureEntityBackend;

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _database.close();
  }
}
