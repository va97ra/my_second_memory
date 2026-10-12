import 'package:ez_domain/ez_domain.dart';
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
    // C, CE, x², 1/x, ± и корень степени меняют всё выражение — по общему
    // правилу, которым нажимает и Джарвис.
    final whole = wholeExpressionKey(key, state.expression);
    if (whole != null) return replace(whole);
    switch (key) {
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
      case 'pi':
        _insert('π');
      case 'e':
        _insert('e');
      case 'Exp':
        _insertExponent();
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
        ? replace(wrapExpression(name, state.expression))
        : _insert('$name(');
  }

  /// Порядок десятки пишется к числу, поэтому `E` без цифры перед ним не
  /// имеет смысла: одинокая буква читалась как число Эйлера, и «Exp» на
  /// пустом поле показывал 2,718. Числа перед курсором нет — значит, порядок
  /// приписывается к нулю, как на клавише и написано.
  void _insertExponent() {
    final selection = textController.selection;
    final start =
        selection.isValid ? selection.start : textController.text.length;
    final previous = start > 0 ? textController.text[start - 1] : '';
    _insert(RegExp(r'\d').hasMatch(previous) ? 'E' : '0E');
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
