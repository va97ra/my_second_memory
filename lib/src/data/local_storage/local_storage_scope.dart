import '../../features/memory_items/data/memory_repository.dart';
import '../../features/recurrence/data/recurrence_exception_repository.dart';
import '../../features/recurrence/data/recurrence_repository.dart';
import '../../features/security/data/secure_entity_backend.dart';

abstract interface class LocalStorageScope {
  MemoryRepository get memoryRepository;

  RecurrenceRepository get recurrenceRepository;

  RecurrenceExceptionRepository get recurrenceExceptionRepository;

  SecureEntityBackend? get secureEntityBackend;

  Future<void> close();
}
