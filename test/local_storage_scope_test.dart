import 'package:ez_data/ez_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ezhednevnik_v2/src/app/local_storage_scope_provider.dart';

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
