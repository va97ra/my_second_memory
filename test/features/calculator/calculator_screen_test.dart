import 'package:ezhednevnik_v2/src/app/app.dart';
import 'package:ezhednevnik_v2/src/features/calculator/ui/widgets/calculator_key.dart';
import 'package:ezhednevnik_v2/src/features/calculator/ui/widgets/calculator_key_grid.dart';
import 'package:ezhednevnik_v2/src/features/calculator/ui/widgets/calculator_mode_bar.dart';
import 'package:ezhednevnik_v2/src/features/calculator/ui/widgets/calculator_scientific_grid.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ezhednevnik_v2/src/features/security/state/security_provider.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/state/shift_schedules_controller.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/widget_test_harness.dart';

void main() {
  useTestEnvironment();

  testWidgets('calculator supports keyboard and cursor insertion',
      (tester) async {
    await _openCalculator(tester, const Size(360, 800));
    final expression = find.byKey(const ValueKey('calculator_expression'));

    await tester.enterText(expression, '0.1+0.2');
    await tester.pump();
    expect(find.text('0.3'), findsOneWidget);

    final field = tester.widget<TextField>(expression);
    field.controller!.selection = const TextSelection.collapsed(offset: 1);
    await tester.tap(find.text('9').last);
    await tester.pump();
    expect(field.controller!.text, '09.1+0.2');

    await tester.enterText(expression, '158+26−946+50');
    await tester.pump();
    expect(find.text('−712'), findsOneWidget);
  });

  testWidgets('scientific toggles change labels without growing the grid',
      (tester) async {
    await _openCalculator(tester, const Size(360, 800));
    await _selectScientific(tester);

    expect(_gridKeys(), findsNWidgets(40));
    expect(find.text('DEG'), findsOneWidget);
    expect(find.text('sin'), findsOneWidget);
    await tester.tap(find.text('2nd'));
    await tester.pump();
    expect(_gridKeys(), findsNWidgets(40));
    expect(find.text('sin⁻¹'), findsOneWidget);
    expect(find.text('2ˣ'), findsOneWidget);
    await tester.tap(find.text('Hyp'));
    await tester.pump();
    expect(find.text('sinh⁻¹'), findsOneWidget);
  });

  testWidgets('keys fill the phone height without scrolling', (tester) async {
    await _openCalculator(tester, const Size(320, 800));
    final standardHeight =
        tester.getSize(_gridKeys().first).height;
    expect(
      tester.getSize(_gridKeys().first).width,
      closeTo(68, 0.1),
    );
    expect(standardHeight, greaterThan(68));
    expect(find.byType(SingleChildScrollView), findsNothing);

    await _selectScientific(tester);
    expect(
      tester.getSize(_gridKeys().first).width,
      closeTo(52.8, 0.1),
    );
    expect(tester.getSize(_gridKeys().first).height,
        lessThan(standardHeight));
  });

  testWidgets('compact display aligns with grid and has no F-E button',
      (tester) async {
    await _openCalculator(tester, const Size(360, 800));
    final display =
        tester.getRect(find.byKey(const ValueKey('calculator_display')));
    final grid = tester.getRect(find.byType(CalculatorKeyGrid));
    final mode = tester.getRect(find.byType(CalculatorModeBar));
    final toolbar = tester.getRect(find.byType(AppToolBar));
    final copy = tester.getRect(find.byTooltip('Копировать результат'));
    final expression = tester.getRect(
      find.byKey(const ValueKey('calculator_expression')),
    );
    final resultPanel = tester.getRect(
      find.byKey(const ValueKey('calculator_result_panel')),
    );

    expect(mode.top - toolbar.bottom, closeTo(2, 0.1));
    expect(display.left, closeTo(grid.left, 0.1));
    expect(display.right, closeTo(grid.right, 0.1));
    expect(expression.left, closeTo(display.left + 4, 0.1));
    expect(expression.right, closeTo(display.right - 4, 0.1));
    expect(copy.right, lessThanOrEqualTo(resultPanel.left));
    expect(resultPanel.height, lessThan(expression.height + 8));
    expect(find.text('F-E'), findsNothing);
    expect(find.byType(SingleChildScrollView), findsNothing);
  });

  testWidgets('key height adapts to available phone height', (tester) async {
    await _openCalculator(tester, const Size(360, 720));
    final shortHeight = tester.getSize(_gridKeys().first).height;

    await tester.binding.setSurfaceSize(const Size(360, 840));
    await tester.pumpAndSettle();
    final tallHeight = tester.getSize(_gridKeys().first).height;

    expect(tallHeight, greaterThan(shortHeight));
  });

  testWidgets('calculator keys are raised and move down while pressed',
      (tester) async {
    await _openCalculator(tester, const Size(360, 800));
    final key = _gridKeys().first;
    final surface = find.descendant(
      of: key,
      matching: find.byType(AnimatedContainer),
    );
    final decoration =
        tester.widget<AnimatedContainer>(surface).decoration as BoxDecoration;
    expect(decoration.boxShadow, isNotEmpty);

    final gesture = await tester.startGesture(tester.getCenter(key));
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester.widget<AnimatedContainer>(surface).transform?.getTranslation().y,
      2,
    );
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester.widget<AnimatedContainer>(surface).transform?.getTranslation().y,
      0,
    );
  });

  testWidgets('wide scientific layout places functions beside number keys',
      (tester) async {
    await _openCalculator(tester, const Size(840, 720));
    await _selectScientific(tester);

    expect(find.byType(CalculatorScientificGrid), findsOneWidget);
    expect(find.byType(CalculatorKeyGrid), findsNWidgets(2));
    expect(_gridKeys(), findsNWidgets(40));
  });

  for (final width in [320.0, 360.0, 600.0, 840.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('calculator has no overflow at ${width}px and ${scale}x',
          (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await _openCalculator(tester, Size(width, 720));
        await _selectScientific(tester);
        expect(tester.takeException(), isNull);
      });
    }
  }
}

Future<void> _selectScientific(WidgetTester tester) async {
  final mode = tester.getRect(find.byKey(const ValueKey('calculator_mode')));
  await tester.tapAt(Offset(mode.left + mode.width * 0.75, mode.center.dy));
  await tester.pump();
}

Future<void> _openCalculator(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    testProviderScope(
      overrides: [
        securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
        memoryRepositoryProvider.overrideWithValue(EmptyMemoryRepository()),
        shiftScheduleRepositoryProvider.overrideWithValue(
          FakeShiftScheduleRepository(),
        ),
      ],
      child: const EzhednevnikV2App(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('top_calculator')));
  await tester.pumpAndSettle();
}

/// Клавиши самой клавиатуры, без строки памяти: она сделана теми же
/// клавишами, и поиск по типу иначе цепляет её первой.
Finder _gridKeys() => find.descendant(
      of: find.byType(CalculatorKeyGrid),
      matching: find.byType(CalculatorKey),
    );
