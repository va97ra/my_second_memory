import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/app/local_storage_scope_provider.dart';
import 'package:ezhednevnik_v2/src/app/provider_retry.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/state/recurrence_exception_controller.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/state/recurrence_providers.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/state/recurrence_series_controller.dart';
import 'package:ezhednevnik_v2/src/features/sync/state/sync_mutation_observer_provider.dart';
import 'package:ezhednevnik_v2/src/shared/state/media_cleanup_provider.dart';
import 'package:ezhednevnik_v2/src/shared/state/notification_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import 'memory_items_test_support.dart';
import 'widget_test_harness.dart';

/// Контейнер с настоящими контроллерами поверх тестовых хранилищ.
///
/// Контроллеры берут зависимости из провайдеров, поэтому тест подменяет
/// провайдеры, а не собирает контроллер руками. По умолчанию записи, повторы
/// и правки дат лежат в SharedPreferences, база — в памяти, напоминания
/// только запоминаются, файлы вложений с диска не удаляются, синхронизации
/// нет. Тест передаёт то, что проверяет; остальное — через [overrides].
///
/// Контейнер закрывается сам в конце теста.
ProviderContainer testContainer({
  MemoryRepository memories = const LocalMemoryRepository(),
  RecurrenceRepository series = const LocalRecurrenceRepository(),
  RecurrenceExceptionRepository exceptions =
      const LocalRecurrenceExceptionRepository(),
  ReminderScheduler? reminders,
  MediaStorage? media,
  SyncMutationObserver sync = const NoopSyncMutationObserver(),
  List<Override> overrides = const [],
}) {
  return ProviderContainer.test(
    retry: noProviderRetry,
    overrides: [
      localStorageScopeFactoryProvider.overrideWithValue(
        TestLocalStorageScope.new,
      ),
      memoryRepositoryProvider.overrideWithValue(memories),
      recurrenceRepositoryProvider.overrideWithValue(series),
      recurrenceExceptionRepositoryProvider.overrideWithValue(exceptions),
      notificationServiceProvider.overrideWithValue(
        reminders ?? FakeReminderScheduler(),
      ),
      mediaStorageProvider.overrideWithValue(media ?? TrackingMediaStorage()),
      syncMutationObserverProvider.overrideWithValue(sync),
      ...overrides,
    ],
  );
}

/// Значение, которое тест меняет сам там, где в приложении оно приходит
/// извне: часы, данные из хранилища.
class TestValue<T> extends Notifier<T> {
  TestValue(this._initial);

  final T _initial;

  @override
  T build() => _initial;

  void set(T value) => state = value;
}

NotifierProvider<TestValue<T>, T> testValueProvider<T>(T initial) =>
    NotifierProvider<TestValue<T>, T>(() => TestValue(initial));

/// Контроллеры записей, правок дат и серий одного контейнера.
typedef Records = ({
  MemoryItemsController memories,
  RecurrenceExceptionController exceptions,
  RecurrenceSeriesController series,
});

/// Записи, повторы и правки дат загружены, как после запуска приложения:
/// уборка вложений решает, что чьё, только когда знает всё.
Future<Records> loadRecords(ProviderContainer container) async {
  await container.read(memoryItemsLoadProvider.future);
  await container.read(recurrenceLoadProvider.future);
  return (
    memories: container.read(memoryItemsControllerProvider.notifier),
    exceptions: container.read(recurrenceExceptionControllerProvider.notifier),
    series: container.read(recurrenceSeriesControllerProvider.notifier),
  );
}
