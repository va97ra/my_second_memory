import 'dart:async';

import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../calculator/state/calculator_controller.dart';
import 'jarvis_controller.dart';
import 'jarvis_outcome.dart';
import 'jarvis_page.dart';

/// Руки Джарвиса на калькуляторе Ежедневника.
///
/// Сам Джарвис не считает: он нажимает те же клавиши, что и палец, и читает
/// ответ с калькулятора (решение владельца 12 октября 2026: «зачем, чтобы
/// и калькулятор, и Джарвис думали одновременно»). Калькулятор на экране —
/// клавиши видно: промялась одна, другая, «=», и ответ звучит. Не на экране
/// — набирает сразу, и посчитанное ждёт на калькуляторе.
class JarvisCalculator {
  JarvisCalculator(this._ref);

  final Ref _ref;

  /// Сколько клавиша промята и пауза до следующей: видно каждое нажатие.
  static const press = Duration(milliseconds: 150);
  static const _between = Duration(milliseconds: 70);

  /// Сколько ждать, пока откроется калькулятор, и пока доиграет переворот.
  static const _arrival = Duration(seconds: 3);
  static const _settle = Duration(milliseconds: 450);

  static const _place = OpenPlace(JarvisPlace.calculator);

  CalculatorController get _keys =>
      _ref.read(calculatorControllerProvider.notifier);
  CalculatorState get _shown => _ref.read(calculatorControllerProvider);
  bool get _onScreen =>
      _ref.read(jarvisPageProvider)?.place == JarvisPlace.calculator;

  /// «Сколько будет 25 на 4»: набрать заново и прочитать ответ.
  /// «Посчитай на калькуляторе» — сначала перейти к нему.
  Future<JarvisOutcome> calculate(Calculate command) async {
    final before = _shown;
    if (command.show && !_onScreen) await _comeToCalculator();
    final keys = keyedExpression(command.expression);
    if (_onScreen) {
      await _type(['C', ...keys.split(''), '=']);
    } else {
      _keys
        ..press('C')
        ..press(keys);
    }
    return JarvisOutcome(
      calculationReply(_shown.evaluation.value, asked: command.expression),
      link: _onScreen ? null : _place,
      undo: _undo(before),
    );
  }

  Future<JarvisOutcome> run(CalculatorCommand command) async {
    final before = _shown;
    final move = command.move;
    if (move == CalculatorMove.chain && before.expression.isEmpty) {
      return JarvisOutcome(calculatorReply(move, empty: true));
    }
    switch (move) {
      case CalculatorMove.chain:
        await _chain(command.tail, before.expression);
      case CalculatorMove.memorySave:
        _keys.memoryCommand('MS');
      case CalculatorMove.memoryAdd:
        _keys.memoryCommand('M+');
      case CalculatorMove.memorySubtract:
        _keys.memoryCommand('M-');
      case CalculatorMove.memoryRecall:
        _keys.memoryCommand('MR');
      case CalculatorMove.memoryClear:
        _keys.memoryCommand('MC');
      case CalculatorMove.clear:
        await _type(const ['C']);
      case CalculatorMove.scientific:
        _keys.setScientific(true);
      case CalculatorMove.basic:
        _keys.setScientific(false);
      case CalculatorMove.degrees:
        _keys.setAngleUnit(CalculatorAngleUnit.degrees);
      case CalculatorMove.radians:
        _keys.setAngleUnit(CalculatorAngleUnit.radians);
      case CalculatorMove.result || CalculatorMove.memoryRead:
        break;
    }
    final after = _shown;
    // Режим видно только на самой странице — её и открыть.
    final shows =
        move == CalculatorMove.scientific || move == CalculatorMove.basic;
    return JarvisOutcome(
      calculatorReply(
        move,
        value: after.evaluation.value,
        memory: after.memory,
        empty: after.expression.isEmpty,
      ),
      open: shows && !_onScreen ? _place : null,
      link: shows || _onScreen ? null : _place,
      undo: identical(after, before) ? null : _undo(before),
    );
  }

  /// Продолжить от того, что на калькуляторе, — теми же клавишами.
  Future<void> _chain(String tail, String expression) async {
    switch (tail) {
      case '^2':
        await _type(const ['square']);
      case '^3':
        _keys.press('cube');
      case 'sqrt':
        _keys.wrap('sqrt');
      default:
        // Умножают результат, а не последнее число: «(25+4)×3».
        final sum = tail.startsWith('+') || tail.startsWith('-');
        if (!sum && hasLooseSum(expression)) _keys.wrap('');
        await _type([...keyedExpression(tail).split(''), '=']);
    }
  }

  /// Нажать клавиши по очереди. Калькулятор на экране — каждая промята
  /// на глазах; нет — нажаты разом.
  Future<void> _type(List<String> keys) async {
    final lit = _ref.read(calculatorLitKeyProvider.notifier);
    final visible = _onScreen;
    for (final key in keys) {
      // Запятая — своя клавиша, точкой её не набрать.
      final pressed = key == '.' ? ',' : key;
      if (visible) lit.state = pressed;
      // «=» выражения не меняет: оно только показывает ответ.
      if (pressed != '=') _keys.press(pressed);
      if (!visible) continue;
      await Future<void>.delayed(press);
      lit.state = null;
      await Future<void>.delayed(_between);
    }
  }

  /// Перейти к калькулятору тем же путём, что «Показать», и дождаться его.
  Future<void> _comeToCalculator() async {
    _ref.read(jarvisControllerProvider.notifier).show(_place);
    final arrived = Completer<void>();
    final watch = _ref.listen(jarvisPageProvider, (_, page) {
      if (page?.place == JarvisPlace.calculator && !arrived.isCompleted) {
        arrived.complete();
      }
    });
    try {
      await arrived.future.timeout(_arrival, onTimeout: () {});
    } finally {
      watch.close();
    }
    if (_onScreen) await Future<void>.delayed(_settle);
  }

  Future<void> Function() _undo(CalculatorState before) =>
      () async => _keys.restore(before);
}
