import 'package:ezhednevnik_v2/src/features/calendar/state/production_preferences.dart';
import 'package:ezhednevnik_v2/src/features/calendar/state/production_progress_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('rapid changes persist and survive controller recreation', () async {
    final controller = ProductionPreferencesController();
    final first = controller.update(highlight: false, weekNumbers: false);
    final last = controller.update(showProgress: false, includeToday: true);
    await Future.wait([first, last]);
    controller.dispose();
    final restored = ProductionPreferencesController();
    addTearDown(restored.dispose);
    await Future<void>.delayed(Duration.zero);
    expect(restored.state.highlight, false);
    expect(restored.state.weekNumbers, false);
    expect(restored.state.showProgress, false);
    expect(restored.state.includeToday, true);
  });

  test('corrupt preferences fall back safely', () async {
    SharedPreferences.setMockInitialValues(
        {ProductionPreferencesController.storageKey: '{broken'});
    final controller = ProductionPreferencesController();
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);
    expect(controller.state.highlight, true);
  });

  test('no shifts means no implicit five-day progress', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(
        container.read(productionProgressProvider(DateTime(2026, 9))), isNull);
  });
}
