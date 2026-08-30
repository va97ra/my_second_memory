import '../memory/local_memory_repository.dart';
import '../memory/memory_repository.dart';
import '../recurrence/local_recurrence_exception_repository.dart';
import '../recurrence/local_recurrence_repository.dart';
import '../recurrence/recurrence_exception_repository.dart';
import '../recurrence/recurrence_repository.dart';
import '../security/secure_entity_backend.dart';
import 'local_storage_scope.dart';
import '../finance/finance_repository.dart';
import '../finance/local_finance_repository.dart';

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
  final FinanceRepository financeRepository = const LocalFinanceRepository();

  @override
  SecureEntityBackend? get secureEntityBackend => null;

  @override
  Future<void> close() async {
    await memoryRepository.close();
    await recurrenceRepository.close();
    await recurrenceExceptionRepository.close();
  }
}
