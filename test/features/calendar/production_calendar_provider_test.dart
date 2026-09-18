import 'dart:async';
import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/calendar/state/production_calendar_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../support/production_calendar_test_support.dart';

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
    final controller = ProductionCalendarController(repo, 2026);
    addTearDown(controller.dispose);
    expect(controller.state.calendar.day(DateTime(2026, 5, 8)),
        ProductionDay.shortened);
    final ready = Completer<void>();
    final remove = controller.addListener((s) {
      if (s.cached != null && !ready.isCompleted) ready.complete();
    });
    addTearDown(remove);
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
    final controller = ProductionCalendarController(repo, 2026);
    addTearDown(controller.dispose);
    final ready = Completer<void>();
    final remove = controller.addListener((s) {
      if (!s.loading && !ready.isCompleted) ready.complete();
    });
    addTearDown(remove);
    await ready.future;
    expect(source.calls, 1);
    await controller.refresh();
    expect(source.calls, 2);
  });
  test('dispose during request does not publish late state', () async {
    final pending = Completer<String>();
    final controller = ProductionCalendarController(
        ProductionCalendarRepository(
            source: FakeProductionSource((_) => pending.future)),
        2026);
    controller.dispose();
    pending.complete(productionFixture());
    await Future<void>.delayed(Duration.zero);
  });
}
