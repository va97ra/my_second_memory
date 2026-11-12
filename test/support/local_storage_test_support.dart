import 'package:ez_data/ez_data.dart';
import 'package:ez_data/ez_data_io.dart';

/// Местное хранилище на базе в памяти: настоящие SQLite-репозитории без файла.
class TestLocalStorage implements LocalStorageScope {
  TestLocalStorage(this.database) {
    memoryRepository = SqliteMemoryRepository(
      database: database,
      closeDatabase: false,
    );
    recurrenceRepository = SqliteRecurrenceRepository(database, false);
    recurrenceExceptionRepository =
        SqliteRecurrenceExceptionRepository(database, false);
    financeRepository = SqliteFinanceRepository(database, false);
    toolDataRepository = SqliteToolDataRepository(database, false);
    secureEntityBackend = DriftSecureEntityBackend(database);
  }

  final AppDatabase database;

  @override
  late final MemoryRepository memoryRepository;

  @override
  late final RecurrenceRepository recurrenceRepository;

  @override
  late final RecurrenceExceptionRepository recurrenceExceptionRepository;

  @override
  late final FinanceRepository financeRepository;

  @override
  late final ToolDataRepository toolDataRepository;

  @override
  late final SecureEntityBackend secureEntityBackend;

  @override
  Future<void> close() => database.close();
}
