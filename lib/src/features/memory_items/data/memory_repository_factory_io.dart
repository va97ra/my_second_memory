import '../../../data/database/shared_app_database.dart';
import 'memory_repository.dart';
import 'sqlite_memory_repository.dart';

MemoryRepository createMemoryRepository() {
  return SqliteMemoryRepository(
    database: sharedAppDatabase,
    closeDatabase: false,
  );
}
