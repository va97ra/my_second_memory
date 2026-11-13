import 'dart:async';
import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/calendar/state/production_calendar_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../support/production_calendar_test_support.dart';
import '../../support/provider_test_support.dart';

/// Календарь года, как его держит экран: подписка не даёт провайдеру
/// закрыться, пока тест смотрит на него.
ProductionCalendarController _calendar(
  ProductionCalendarRepository repository, {
  void Function(ProductionCalendarState state)? onChange,
}) {
  final container = testContainer(overrides: [
    productionCalendarRepositoryProvider.overrideWithValue(repository),
  ]);
  final subscription = container.listen(
    productionCalendarProvider(2026),
    (_, next) => onChange?.call(next),
  );
  addTearDown(subscription.close);
  return container.read(productionCalendarProvider(2026).notifier);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
      'shows official fallback immediately, then updates, keeping data after failure',
      () async {
    final pending = Completer<String>();
    var fail = false;
    final repo = ProductionCalendarRepository(
        source: FakeProductionSource((_) =>
            fail ? Future.error(StateError('offline')) : pending.future));
    final ready = Completer<void>();
    final controller = _calendar(repo, onChange: (s) {
      if (s.cached != null && !ready.isCompleted) ready.complete();
    });
    expect(controller.state.calendar.day(DateTime(2026, 5, 8)),
        ProductionDay.shortened);
    pending.complete(productionFixture());
    await ready.future;
    expect(controller.state.failed, isFalse);
    fail = true;
    await controller.refresh();
    expect(controller.state.failed, isTrue);
    expect(controller.state.cached, isNotNull);
  });
  test('fresh disk cache avoids network; manual refresh still requests',
      () async {
    final source = FakeProductionSource((_) async => productionFixture());
    final repo = ProductionCalendarRepository(source: source);
    await repo.refresh(2026);
    final ready = Completer<void>();
    final controller = _calendar(repo, onChange: (s) {
      if (!s.loading && !ready.isCompleted) ready.complete();
    });
    await ready.future;
    expect(source.calls, 1);
    await controller.refresh();
    expect(source.calls, 2);
  });
  test('dispose during request does not publish late state', () async {
    final pending = Completer<String>();
    final container = testContainer(overrides: [
      productionCalendarRepositoryProvider.overrideWithValue(
          ProductionCalendarRepository(
              source: FakeProductionSource((_) => pending.future))),
    ]);
    container.listen(productionCalendarProvider(2026), (_, __) {}).close();
    // Последний слушатель ушёл: провайдер закрывается, пока запрос в пути.
    await Future<void>.delayed(Duration.zero);
    pending.complete(productionFixture());
    await Future<void>.delayed(Duration.zero);
  });
}
