import 'local_memory_repository.dart';
import 'memory_repository.dart';

MemoryRepository createMemoryRepository() {
  return const LocalMemoryRepository();
}
