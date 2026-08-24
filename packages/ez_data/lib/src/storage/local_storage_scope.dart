import '../memory/memory_repository.dart';
import '../recurrence/recurrence_exception_repository.dart';
import '../recurrence/recurrence_repository.dart';
import '../security/secure_entity_backend.dart';

abstract interface class LocalStorageScope {
  MemoryRepository get memoryRepository;

  RecurrenceRepository get recurrenceRepository;

  RecurrenceExceptionRepository get recurrenceExceptionRepository;

  SecureEntityBackend? get secureEntityBackend;

  Future<void> close();
}
