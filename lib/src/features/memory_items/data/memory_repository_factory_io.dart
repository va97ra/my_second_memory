import 'memory_repository.dart';
import 'sqlite_memory_repository.dart';

MemoryRepository createMemoryRepository() {
  return SqliteMemoryRepository();
}
