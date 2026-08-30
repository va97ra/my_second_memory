import '../memory/memory_repository.dart';
import '../memory/sqlite_memory_repository.dart';
import '../recurrence/recurrence_exception_repository.dart';
import '../recurrence/recurrence_repository.dart';
import '../recurrence/sqlite_recurrence_exception_repository.dart';
import '../recurrence/sqlite_recurrence_repository.dart';
import '../security/secure_entity_backend.dart';
import '../database/app_database.dart';
import '../database/drift_secure_entity_backend.dart';
import 'local_storage_scope.dart';
import '../finance/finance_repository.dart';
import '../finance/sqlite_finance_repository.dart';
import '../tools/sqlite_tool_data_repository.dart';
import '../tools/tool_data_repository.dart';

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
    financeRepository = SqliteFinanceRepository(_database, false);
    toolDataRepository = SqliteToolDataRepository(_database, false);
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
  late final FinanceRepository financeRepository;

  @override
  late final ToolDataRepository toolDataRepository;

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _database.close();
  }
}
