import 'package:ez_data/ez_data.dart';
import 'package:ezhednevnik_v2/src/features/calendar/state/calendar_today_provider.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/state/recurrence_exception_controller.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/state/recurrence_providers.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/state/recurrence_series_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/recurrence_test_support.dart';

/// Б8: ближайшее вхождение повтора считается от сегодняшнего дня и
/// сдвигается, когда день сменился, а не стоит на дате запуска.
void main() {
  test('the nearest occurrence moves on when the day changes', () async {
    final (:series, override: _) = seriesWithMedia();
    SharedPreferences.setMockInitialValues({
      'memory_items_v1': '[]',
      LocalRecurrenceRepository.storageKey: encodeSeries([series]),
      LocalRecurrenceExceptionRepository.storageKey: '[]',
    });
    final memories = MemoryItemsController(const LocalMemoryRepository());
    final exceptions = RecurrenceExceptionController(
      const LocalRecurrenceExceptionRepository(),
    );
    final reminders = NotificationService();
    addTearDown(reminders.dispose);
    final controller = RecurrenceSeriesController(
      const LocalRecurrenceRepository(),
      exceptions,
      memories,
      reminders,
    );
    await controller.load();
    final today = StateProvider<DateTime>((_) => DateTime(2099, 1, 9));
    final container = ProviderContainer(overrides: [
      memoryItemsControllerProvider.overrideWith((_) => memories),
      recurrenceExceptionControllerProvider.overrideWith((_) => exceptions),
      recurrenceSeriesControllerProvider.overrideWith((_) => controller),
      calendarTodayProvider.overrideWith((ref) => ref.watch(today)),
    ]);
    addTearDown(container.dispose);
    final subscription =
        container.listen(nextRecurrenceItemsProvider, (_, __) {});
    addTearDown(subscription.close);

    expect(subscription.read().single.memoryDate, DateTime(2099, 1, 9));

    container.read(today.notifier).state = DateTime(2099, 1, 10);

    expect(subscription.read().single.memoryDate, DateTime(2099, 2, 9));
  });
}
