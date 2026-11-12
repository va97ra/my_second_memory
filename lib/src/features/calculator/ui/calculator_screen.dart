import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/calculator_controller.dart';
import 'calculator_input_handler.dart';
import 'calculator_key_layouts.dart';
import 'widgets/calculator_display.dart';
import 'widgets/calculator_key.dart';
import 'widgets/calculator_key_grid.dart';
import 'widgets/calculator_mode_bar.dart';

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
          // Раскладку выбирает форма места под клавиатуру, а не ширина экрана.
          // Порог по ширине давал широкую раскладку и планшету в портрете,
          // где высоты вдвое больше ширины: пять рядов растягивались на всю
          // высоту, а клавиши превращались в вертикальные плашки.
          final keyboardHeight = constraints.maxHeight - _chromeHeight;
          final wideScientific =
              state.scientific && constraints.maxWidth - 24 > keyboardHeight;
          // Потолок ширины держит клавиатуру осмысленной на десктопе, но не
          // должен обрезать её на телефоне: 360 совпадали ровно с узким
          // экраном, и всё, что шире, получало поля по бокам. 480 перекрывают
          // любой телефон, и клавиши доходят до краёв везде, где это уместно.
          final width = constraints.maxWidth.clamp(
            0.0,
            wideScientific
                ? 760.0
                : state.scientific
                    ? 560.0
                    : 480.0,
          );
          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: width,
              height: constraints.maxHeight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  calculatorKeyGap,
                  2,
                  calculatorKeyGap,
                  calculatorKeyGap,
                ),
                child: Column(
                  children: [
                    CalculatorModeBar(
                      hint: strings.calculatorPageHint,
                      standardLabel: strings.calculatorStandard,
                      scientificLabel: strings.calculatorScientific,
                      scientific: state.scientific,
                      onModeChanged: ref
                          .read(calculatorControllerProvider.notifier)
                          .setScientific,
                    ),
                    const SizedBox(height: calculatorKeyGap),
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
                    const SizedBox(height: calculatorKeyGap),
                    SizedBox(height: 44, child: _memoryRow()),
                    const SizedBox(height: calculatorKeyGap),
                    Expanded(
                      child: CalculatorKeyGrid(
                        layout: state.scientific
                            ? scientificCalculatorLayout(
                                state,
                                wide: wideScientific,
                              )
                            : standardCalculatorLayout,
                        selectedKeys: calculatorSelectedKeys(state),
                        labels: calculatorKeyLabels(state, strings),
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

  /// Память: те же клавиши, что и остальные, а не подписи без кнопок.
  /// Голый текст не читался нажимаемым — было непонятно, что по нему вообще
  /// можно ударить пальцем. Своя краска отделяет ряд от цифр.
  Widget _memoryRow() => Row(
        children: [
          for (final command in const ['MC', 'MR', 'M+', 'M-', 'MS']) ...[
            if (command != 'MC') const SizedBox(width: calculatorKeyGap),
            Expanded(
              child: CalculatorKey(
                label: command,
                role: CalculatorKeyRole.memory,
                onPressed: () => ref
                    .read(calculatorControllerProvider.notifier)
                    .memoryCommand(command),
              ),
            ),
          ],
        ],
      );
}

/// Высота всего, что стоит над клавиатурой: полоса режима, табло, ряд памяти
/// и зазоры между ними вместе с полями колонки.
const double _chromeHeight = 2 +
    calculatorModeBarHeight +
    calculatorKeyGap +
    100 +
    calculatorKeyGap +
    44 +
    calculatorKeyGap +
    calculatorKeyGap;
