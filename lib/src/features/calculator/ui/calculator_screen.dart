import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/calculator_controller.dart';
import 'calculator_input_handler.dart';
import 'calculator_key_layouts.dart';
import 'widgets/calculator_display.dart';
import 'widgets/calculator_key_grid.dart';
import 'widgets/calculator_mode_bar.dart';
import 'widgets/calculator_scientific_grid.dart';

class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  late final TextEditingController _textController;
  late final CalculatorInputHandler _input;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: ref.read(calculatorControllerProvider).expression,
    );
    _input = CalculatorInputHandler(
      textController: _textController,
      stateController: ref.read(calculatorControllerProvider.notifier),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      calculatorControllerProvider.select((value) => value.expression),
      (_, expression) => _input.syncExpression(expression),
    );
    final state = ref.watch(calculatorControllerProvider);
    final strings = AppStrings.of(context);
    return WarmGradientBackground(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wideScientific =
              state.scientific && constraints.maxWidth >= 600;
          final width = constraints.maxWidth.clamp(
            0.0,
            wideScientific
                ? 760.0
                : state.scientific
                    ? 440.0
                    : 360.0,
          );
          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: width,
              height: constraints.maxHeight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
                child: Column(
                  children: [
                    CalculatorModeBar(
                      standardLabel: strings.calculatorStandard,
                      scientificLabel: strings.calculatorScientific,
                      scientific: state.scientific,
                      onModeChanged: ref
                          .read(calculatorControllerProvider.notifier)
                          .setScientific,
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      height: 100,
                      child: CalculatorDisplay(
                        controller: _textController,
                        evaluation: state.evaluation,
                        onChanged: ref
                            .read(calculatorControllerProvider.notifier)
                            .updateExpression,
                        onSubmitted: (_) => ref
                            .read(calculatorControllerProvider.notifier)
                            .commit(),
                      ),
                    ),
                    const SizedBox(height: 2),
                    SizedBox(height: 48, child: _memoryRow()),
                    const SizedBox(height: 2),
                    Expanded(
                      child: state.scientific
                          ? CalculatorScientificGrid(
                              keys: scientificCalculatorKeys(state),
                              wide: wideScientific,
                              selectedKeys: _selectedKeys(state),
                              labels: _scientificLabels(state),
                              onKey: (key) => _input.handle(key, state),
                            )
                          : CalculatorKeyGrid(
                              columns: 4,
                              keys: standardCalculatorKeys,
                              onKey: (key) => _input.handle(key, state),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _memoryRow() => Row(
        children: [
          for (final command in const ['MC', 'MR', 'M+', 'M-', 'MS'])
            Expanded(
              child: TextButton(
                onPressed: () => ref
                    .read(calculatorControllerProvider.notifier)
                    .memoryCommand(command),
                child: Text(command),
              ),
            ),
        ],
      );

  String _functionLabel(String name, CalculatorState state) {
    final base = state.hyperbolic ? '${name}h' : name;
    return state.second ? '$base⁻¹' : base;
  }

  Set<String> _selectedKeys(CalculatorState state) => {
        if (state.second) '2nd',
        if (state.hyperbolic) 'Hyp',
      };

  Map<String, String> _scientificLabels(CalculatorState state) => {
        'angle': switch (state.angleUnit) {
          CalculatorAngleUnit.degrees => 'DEG',
          CalculatorAngleUnit.radians => 'RAD',
          CalculatorAngleUnit.gradians => 'GRAD',
        },
        'sin': _functionLabel('sin', state),
        'cos': _functionLabel('cos', state),
        'tan': _functionLabel('tan', state),
        'ln': state.second ? 'eˣ' : 'ln',
        'log': state.second ? '10ˣ' : 'log',
        '10ˣ': state.second ? '2ˣ' : '10ˣ',
        'pi': state.second ? 'e' : 'π',
      };
}
