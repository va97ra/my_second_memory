import '../../features/memory_items/data/local_memory_repository.dart';
import '../../features/memory_items/data/memory_repository.dart';
import '../../features/recurrence/data/local_recurrence_exception_repository.dart';
import '../../features/recurrence/data/local_recurrence_repository.dart';
import '../../features/recurrence/data/recurrence_exception_repository.dart';
import '../../features/recurrence/data/recurrence_repository.dart';
import '../../features/security/data/secure_entity_backend.dart';
import 'local_storage_scope.dart';

LocalStorageScope createLocalStorageScope() => WebLocalStorageScope();

class WebLocalStorageScope implements LocalStorageScope {
  @override
  final MemoryRepository memoryRepository = const LocalMemoryRepository();

  @override
  final RecurrenceRepository recurrenceRepository =
      const LocalRecurrenceRepository();

  @override
  final RecurrenceExceptionRepository recurrenceExceptionRepository =
      const LocalRecurrenceExceptionRepository();

  @override
  SecureEntityBackend? get secureEntityBackend => null;

  @override
  Future<void> close() async {
    await memoryRepository.close();
    await recurrenceRepository.close();
    await recurrenceExceptionRepository.close();
  }
}
