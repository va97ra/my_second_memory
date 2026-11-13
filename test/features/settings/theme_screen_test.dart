import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/app/app.dart';
import 'package:ezhednevnik_v2/src/app/theme/app_theme_colors_controller.dart';
import 'package:ezhednevnik_v2/src/app/theme/app_theme_controller.dart';
import 'package:ezhednevnik_v2/src/features/security/security.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/state/shift_schedules_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/widget_test_harness.dart';

/// Карточка темы: открывается с плитки, показывает образцы и меняет цвета
/// только своей темы.
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

  Future<ProviderContainer> open(
    WidgetTester tester, {
    required List<ShiftSchedule> schedules,
    AppThemeStyle style = AppThemeStyle.notebookDark,
    double width = 411,
  }) async {
    await tester.binding.setSurfaceSize(Size(width, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(testProviderScope(
      overrides: [
        securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
        shiftScheduleRepositoryProvider.overrideWithValue(
          FakeShiftScheduleRepository(schedules),
        ),
      ],
      child: const EzhednevnikV2App(),
    ));
    await tester.pumpAndSettle();
    await openTab(tester, 'settings');
    await tester.tap(find.byKey(ValueKey('settings_theme_${style.name}')));
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(
      tester.element(find.byKey(const ValueKey('theme_color_weekend'))),
    );
  }

  testWidgets('the tile opens the card instead of switching the theme',
      (tester) async {
    final c = await open(tester, schedules: const []);
    expect(c.read(appThemeControllerProvider), AppThemeStyle.notebookLight);
    expect(find.byKey(const ValueKey('theme_enable')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('theme_enable')));
    // Тема включается после подгрузки кожи, а у неё в тестах только таймаут.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(c.read(appThemeControllerProvider), AppThemeStyle.notebookDark);
    expect(find.byKey(const ValueKey('theme_enable')), findsNothing);
  });

  testWidgets('shift schedules appear only when one exists', (tester) async {
    await open(tester, schedules: const []);
    expect(find.text('Графики смен'), findsNothing);
    expect(find.byKey(const ValueKey('theme_color_shift_s1')), findsNothing);
  });

  testWidgets('a schedule gets its own sample', (tester) async {
    await open(tester, schedules: [schedule]);
    expect(find.byKey(const ValueKey('theme_color_shift_s1')), findsOneWidget);
    expect(find.text('Завод'), findsOneWidget);
  });

  testWidgets('dragging a track recolours only this theme, and reset undoes it',
      (tester) async {
    final c = await open(tester, schedules: const []);
    AppThemeColors colors(AppThemeStyle style) =>
        c.read(appThemeColorsControllerProvider)[style]!;

    await tester.drag(
      find.byKey(const ValueKey('theme_color_hue')),
      const Offset(-120, 0),
    );
    await tester.pumpAndSettle();
    final dark = colors(AppThemeStyle.notebookDark);
    expect(dark.isChanged(AppColorRole.weekend), isTrue);
    expect(colors(AppThemeStyle.notebookLight).chosen, isEmpty);

    await tester.tap(find.byKey(const ValueKey('theme_color_reset')));
    await tester.pumpAndSettle();
    expect(colors(AppThemeStyle.notebookDark).chosen, isEmpty);
  });

  for (final width in [320.0, 360.0, 600.0, 840.0]) {
    testWidgets('the card fits at width $width', (tester) async {
      await open(tester, schedules: [schedule], width: width);
      expect(tester.takeException(), isNull);
    });
  }
}
