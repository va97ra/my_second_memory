import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/app/local_storage_scope_provider.dart';
import 'package:ezhednevnik_v2/src/features/finance/finance.dart';
import 'package:ezhednevnik_v2/src/features/jarvis/state/jarvis_briefings.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/memory_items.dart';
import 'package:ezhednevnik_v2/src/features/security/security.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/shift_schedules.dart';
import 'package:ezhednevnik_v2/src/shared/state/notification_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_items_test_support.dart';
import '../../support/widget_test_harness.dart';

/// Сводки Джарвиса ставятся на неделю вперёд и только на дни с делами.
void main() {
  useTestEnvironment();
  final now = DateTime(2026, 10, 9, 10);

  MemoryItem task(String title, DateTime day, {int? minutes}) => MemoryItem(
        id: title,
        type: MemoryType.task,
        title: title,
        memoryDate: day,
        timeMinutes: minutes,
        createdAt: now,
        updatedAt: now,
      );

  final items = {
    DateTime(2026, 10, 9): [task('Отчёт', DateTime(2026, 10, 9), minutes: 900)],
    DateTime(2026, 10, 10): [task('Врач', DateTime(2026, 10, 10), minutes: 600)],
  };

  final planner = Provider((ref) => JarvisBriefings(ref));

  /// Смены и финансы — настоящие, на пустом тестовом хранилище: сводка
  /// читает их для своих подсказок. Загрузка дожидается, иначе она
  /// дописывает уже закрытые контроллеры.
  Future<ProviderContainer> container() async {
    final container = ProviderContainer(overrides: [
      localStorageScopeFactoryProvider
          .overrideWithValue(TestLocalStorageScope.new),
      securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
      notificationServiceProvider.overrideWithValue(FakeReminderScheduler()),
      memoryItemsForDayProvider.overrideWith(
        (ref, day) => items[DateTime(day.year, day.month, day.day)] ?? const [],
      ),
    ]);
    addTearDown(container.dispose);
    await container.read(shiftSchedulesControllerProvider.notifier).load();
    await container.read(financeControllerProvider.notifier).load();
    await container.read(financeCurrencyProvider.notifier).load();
    return container;
  }

  test('утро уже прошло — сегодня только вечер про завтра', () async {
    final briefings = (await container()).read(planner).briefings(now);
    expect(briefings, hasLength(3));
    final evening = briefings[0];
    expect(evening.at, DateTime(2026, 10, 9, 20));
    expect(evening.day, DateTime(2026, 10, 10));
    expect(evening.title, 'Сэр, на завтра одно дело');
    final morning = briefings[1];
    expect(morning.at, DateTime(2026, 10, 10, 9));
    expect(morning.title, 'Доброе утро, сэр! На сегодня одно дело');
    // Дел 11-го нет, но Джарвис напомнит о неотмеченном накануне — если
    // врача отметят, сводка переставится без этой строки.
    final after = briefings[2];
    expect(after.at, DateTime(2026, 10, 11, 9));
    expect(after.title, 'Доброе утро, сэр! На сегодня дел нет');
    expect(after.body, 'Вчера не отмечено: врач.');
  });

  test('выключенная сводка не ставится, время берётся из настроек', () async {
    final scope = await container();
    await scope
        .read(jarvisBriefingSettingsProvider.notifier)
        .setEvening(enabled: false);
    await scope
        .read(jarvisBriefingSettingsProvider.notifier)
        .setMorning(at: 7 * 60 + 30);
    final briefings = scope.read(planner).briefings(now);
    expect(briefings.first.at, DateTime(2026, 10, 10, 7, 30));
    expect(briefings.every((briefing) => briefing.at.hour == 7), isTrue,
        reason: 'вечерняя выключена');
  });
}
