import 'package:ezhednevnik_v2/src/features/calculator/state/calculator_controller.dart';
import 'package:ezhednevnik_v2/src/features/calculator/ui/calculator_key_layouts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('both scientific layouts hold the same keys', () {
    for (final state in const [
      CalculatorState(scientific: true),
      CalculatorState(scientific: true, second: true),
    ]) {
      final tall = scientificCalculatorLayout(state, wide: false);
      final wide = scientificCalculatorLayout(state, wide: true);

      expect(tall.keys.toSet(), wide.keys.toSet());
      expect(tall.keys.length, wide.keys.length);
      expect(tall.keys.length % tall.columns, 0);
      expect(wide.keys.length % wide.columns, 0);
    }
  });

  test('every layout places each key once', () {
    final layouts = [
      standardCalculatorLayout,
      scientificCalculatorLayout(const CalculatorState(), wide: false),
      scientificCalculatorLayout(const CalculatorState(), wide: true),
    ];
    for (final layout in layouts) {
      expect(layout.keys.toSet().length, layout.keys.length);
    }
  });

  test('the action column runs down the last column of every layout', () {
    for (final layout in [
      standardCalculatorLayout,
      scientificCalculatorLayout(const CalculatorState(), wide: false),
      scientificCalculatorLayout(const CalculatorState(), wide: true),
    ]) {
      final columns = <int>{};
      for (var i = 0; i < layout.keys.length; i++) {
        if (const ['÷', '×', '−', '+', '='].contains(layout.keys[i])) {
          columns.add(i % layout.columns);
        }
      }
      expect(columns, {layout.columns - 1});
    }
  });
}
