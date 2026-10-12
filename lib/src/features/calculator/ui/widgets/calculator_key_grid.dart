import 'package:flutter/material.dart';

import '../calculator_key_layouts.dart';
import 'calculator_key.dart';

/// Насколько клавиша может быть выше своей ширины.
///
/// Без потолка `Expanded` растягивал ряды на всю доступную высоту, и на
/// планшете в портрете клавиши превращались в вертикальные плашки. Лишнюю
/// высоту лучше отдать полям, чем строке цифр.
const double _maxKeyAspect = 1.25;

/// Промежуток между клавишами — один по вертикали и горизонтали: сетка, а
/// не полосы. Ряды стояли почти вплотную (2 точки), и клавиши сливались.
const double _gap = 8;

class CalculatorKeyGrid extends StatelessWidget {
  const CalculatorKeyGrid({
    required this.layout,
    required this.onKey,
    this.selectedKeys = const {},
    this.labels = const {},
    this.litKey,
    super.key,
  });

  final CalculatorKeyLayout layout;
  final ValueChanged<String> onKey;
  final Set<String> selectedKeys;
  final Map<String, String> labels;

  /// Клавиша, которую сейчас нажимает Джарвис.
  final String? litKey;

  int get columns => layout.columns;

  @override
  Widget build(BuildContext context) {
    final rowCount = layout.keys.length ~/ columns;
    return LayoutBuilder(
      builder: (context, constraints) {
        final keyWidth =
            (constraints.maxWidth - _gap * (columns - 1)) / columns;
        final rowHeight =
            (constraints.maxHeight - _gap * (rowCount - 1)) / rowCount;
        final height = rowHeight <= keyWidth * _maxKeyAspect
            ? constraints.maxHeight
            : keyWidth * _maxKeyAspect * rowCount + _gap * (rowCount - 1);
        return Center(
          child: SizedBox(
            height: height,
            child: Column(
              children: [
                for (var row = 0; row < rowCount; row++) ...[
                  Expanded(
                    child: Row(
                      children: [
                        for (var column = 0; column < columns; column++) ...[
                          if (column > 0) const SizedBox(width: _gap),
                          Expanded(
                            child: _key(layout.keys[row * columns + column]),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (row < rowCount - 1) const SizedBox(height: _gap),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _key(String keyValue) => CalculatorKey(
        label: labels[keyValue] ?? _label(keyValue),
        icon: keyValue == 'backspace' ? Icons.backspace_outlined : null,
        selected: selectedKeys.contains(keyValue),
        lit: keyValue == litKey,
        role: calculatorKeyRole(keyValue),
        onPressed: () => onKey(keyValue),
      );

  /// Подписи собраны из знаков, которые есть в шрифте клавиатуры. Кубический
  /// корень как единый знак `∛` в нём отсутствует и приезжал из чужого шрифта,
  /// поэтому степень тройки ставится отдельным знаком перед корнем. Подпись
  /// клавиши стирания приходит переводом: у неё значок, а не знак.
  String _label(String value) => switch (value) {
        'sqrt' => '√',
        'cbrt' => '³√',
        'square' => 'x²',
        'cube' => 'x³',
        'power' => 'xʸ',
        'root' => 'ʸ√x',
        'reciprocal' => '1/x',
        'sign' => '±',
        'abs' => '|x|',
        'factorial' => 'n!',
        'angle' => 'DEG',
        'pi' => 'π',
        _ => value,
      };
}
