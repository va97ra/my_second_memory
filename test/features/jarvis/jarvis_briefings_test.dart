import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/jarvis/state/jarvis_briefings.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/memory_items.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сводки Джарвиса ставятся на неделю вперёд и только на дни с делами.
void main() {
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

  ProviderContainer container() {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(overrides: [
      memoryItemsForDayProvider.overrideWith(
        (ref, day) => items[DateTime(day.year, day.month, day.day)] ?? const [],
      ),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  test('утро уже прошло — сегодня только вечер про завтра', () {
    final briefings = container().read(planner).briefings(now);
    expect(briefings, hasLength(2));
    final evening = briefings.first;
    expect(evening.at, DateTime(2026, 10, 9, 20));
    expect(evening.day, DateTime(2026, 10, 10));
    expect(evening.title, 'Сэр, на завтра одно дело');
    final morning = briefings.last;
    expect(morning.at, DateTime(2026, 10, 10, 9));
    expect(morning.title, 'Доброе утро, сэр! На сегодня одно дело');
  });

  test('выключенная сводка не ставится, время берётся из настроек', () async {
    final scope = container();
    await scope
        .read(jarvisBriefingSettingsProvider.notifier)
        .setEvening(enabled: false);
    await scope
        .read(jarvisBriefingSettingsProvider.notifier)
        .setMorning(at: 7 * 60 + 30);
    final briefings = scope.read(planner).briefings(now);
    expect(briefings.single.at, DateTime(2026, 10, 10, 7, 30));
  });
}
