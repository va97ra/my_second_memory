import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/app/app.dart';
import 'package:ezhednevnik_v2/src/features/security/security.dart';
import 'package:ezhednevnik_v2/src/features/settings/settings.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/state/shift_schedules_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/widget_test_harness.dart';

void main() {
  useTestEnvironment();

  final schedule = ShiftSchedule(
    id: 's1',
    organizationName: 'Завод',
    colorValue: 0xFF3D5BFF,
    startDate: DateTime(2026, 11, 1),
    workDays: 2,
    restDays: 2,
  );

  Future<ProviderContainer> open(WidgetTester tester, double width) async {
    await tester.binding.setSurfaceSize(Size(width, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(testProviderScope(
      overrides: [
        securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
        shiftScheduleRepositoryProvider.overrideWithValue(
          FakeShiftScheduleRepository([schedule]),
        ),
      ],
      child: const EzhednevnikV2App(),
    ));
    await tester.pumpAndSettle();
    await openTab(tester, 'settings');
    final tile = find.text('Графики смен');
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(tester.element(find.text('Завод')));
  }

  for (final width in [320.0, 360.0, 600.0, 840.0]) {
    testWidgets('карточка графика умещается на ширине $width', (tester) async {
      await open(tester, width);
      expect(find.text('2/2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('переключатель выключает график, а не открывает редактор',
      (tester) async {
    final c = await open(tester, 411);
    expect(tester.widget<SettingsToggle>(find.byType(SettingsToggle)).value,
        isTrue);

    await tester.tap(find.byKey(const ValueKey('shift_schedule_toggle_s1')));
    await tester.pumpAndSettle();

    expect(c.read(shiftSchedulesControllerProvider).single.isEnabled, isFalse);
    expect(find.text('Редактировать график'), findsNothing);
  });

  testWidgets('нажатие на карточку открывает редактор', (tester) async {
    await open(tester, 411);
    await tester.tap(find.text('Завод'));
    await tester.pumpAndSettle();
    expect(find.text('Редактировать график'), findsWidgets);
  });

  testWidgets('удаление из меню спрашивает подтверждение', (tester) async {
    final c = await open(tester, 411);
    await tester.tap(find.byKey(const ValueKey('shift_schedule_menu_s1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('shift_schedule_menu_delete')));
    await tester.pumpAndSettle();
    expect(c.read(shiftSchedulesControllerProvider), hasLength(1));

    await tester.tap(find.widgetWithText(FilledButton, 'Удалить'));
    await tester.pumpAndSettle();
    expect(c.read(shiftSchedulesControllerProvider), isEmpty);
  });
}
