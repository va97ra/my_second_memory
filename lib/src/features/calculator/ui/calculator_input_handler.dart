import 'package:flutter/widgets.dart';

import '../state/calculator_controller.dart';

class CalculatorInputHandler {
  CalculatorInputHandler({
    required this.textController,
    required this.stateController,
  });

  final TextEditingController textController;
  final CalculatorController stateController;

  void handle(String key, CalculatorState state) {
    switch (key) {
      case 'C':
        replace('');
      case 'CE':
        replace(state.expression.replaceFirst(RegExp(r'[\d.]+$'), ''));
      case 'backspace':
        _deleteSelection();
      case '=':
        stateController.commit();
      case '2nd':
        stateController.toggleSecond();
      case 'Hyp':
        stateController.toggleHyperbolic();
      case 'angle':
        stateController.cycleAngleUnit();
      case 'sign':
        replace(state.expression.startsWith('-')
            ? state.expression.substring(1)
            : '-(${state.expression})');
      case 'square':
        replace('(${state.expression})^2');
      case 'cube':
        replace('(${state.expression})^3');
      case 'reciprocal':
        replace('1/(${state.expression})');
      case 'sqrt':
        _function('sqrt', state);
      case 'cbrt':
        _function('cbrt', state);
      case 'abs':
        _function('abs', state);
      case 'factorial':
        _insert('!');
      case 'power':
        _insert('^');
      case 'root':
        replace('root(${state.expression};');
      case 'pi':
        _insert(state.second ? 'e' : 'π');
      case 'Exp':
        _insert('E');
      case 'Mod':
        _insert('mod');
      case 'sin' || 'cos' || 'tan':
        final name = state.hyperbolic ? '${key}h' : key;
        _function(state.second ? 'a$name' : name, state);
      case 'ln':
        _function(state.second ? 'exp' : 'ln', state);
      case 'log':
        _function(state.second ? 'exp10' : 'log', state);
      case '10ˣ':
        _function(state.second ? 'exp2' : 'exp10', state);
      case 'eˣ':
        _function('exp', state);
      default:
        _insert(key);
    }
  }

  void syncExpression(String expression) {
    if (textController.text == expression) return;
    textController.value = TextEditingValue(
      text: expression,
      selection: TextSelection.collapsed(offset: expression.length),
    );
  }

  void replace(String value, [int? cursor]) {
    textController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: cursor ?? value.length),
    );
    stateController.updateExpression(value);
  }

  void _function(String name, CalculatorState state) {
    state.evaluation.isValid
        ? replace('$name(${state.expression})')
        : _insert('$name(');
  }

  void _insert(String value) {
    final selection = textController.selection;
    final start =
        selection.isValid ? selection.start : textController.text.length;
    final end = selection.isValid ? selection.end : start;
    replace(
      textController.text.replaceRange(start, end, value),
      start + value.length,
    );
  }

  void _deleteSelection() {
    final selection = textController.selection;
    final end = selection.isValid ? selection.end : textController.text.length;
    final start = selection.isValid && selection.start != selection.end
        ? selection.start
        : (end - 1).clamp(0, end);
    if (start == end) return;
    replace(textController.text.replaceRange(start, end, ''), start);
  }
}
