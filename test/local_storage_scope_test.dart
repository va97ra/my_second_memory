import 'package:ezhednevnik_v2/src/data/local_storage/local_storage_scope.dart';
import 'package:ezhednevnik_v2/src/data/local_storage/local_storage_scope_provider.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/data/local_memory_repository.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/data/memory_repository.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/data/local_recurrence_exception_repository.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/data/local_recurrence_repository.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/data/recurrence_exception_repository.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/data/recurrence_repository.dart';
import 'package:ezhednevnik_v2/src/features/security/data/secure_entity_backend.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ProviderContainer closes its local storage scope exactly once',
      () async {
    final scope = _CountingLocalStorageScope();
    final container = ProviderContainer(
      overrides: [
        localStorageScopeFactoryProvider.overrideWithValue(() => scope),
      ],
    );

    expect(container.read(localStorageScopeProvider), same(scope));
    container.dispose();
    await Future<void>.delayed(Duration.zero);

    expect(scope.closeCalls, 1);
  });
}

class _CountingLocalStorageScope implements LocalStorageScope {
  int closeCalls = 0;

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
    closeCalls++;
  }
}
