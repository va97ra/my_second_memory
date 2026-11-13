import 'package:ez_data/ez_data.dart';
import 'package:ezhednevnik_v2/src/features/calendar/state/calendar_today_provider.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/state/recurrence_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/provider_test_support.dart';
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
    final today = testValueProvider(DateTime(2099, 1, 9));
    final container = testContainer(overrides: [
      calendarTodayProvider.overrideWith((ref) => ref.watch(today)),
    ]);
    await loadRecords(container);
    final subscription =
        container.listen(nextRecurrenceItemsProvider, (_, __) {});
    addTearDown(subscription.close);

    expect(subscription.read().single.memoryDate, DateTime(2099, 1, 9));

    container.read(today.notifier).set(DateTime(2099, 1, 10));

    expect(subscription.read().single.memoryDate, DateTime(2099, 2, 9));
  });
}
