import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import '../../state/converter_controller.dart';
import 'converter_category_field.dart';

/// Ширина, которую кнопка обмена занимает между колонками.
///
/// Одна на обе строки: единицы выстраиваются под единицами, а числа под
/// числами, только пока середина у строк общая.
const double _swapSlot = 52;

/// Высота поля с рамкой `OutlineInputBorder` в этой теме.
const double _fieldHeight = 56;

/// Конвертер целиком: величина длинной строкой сверху, под ней две колонки —
/// «что переводим» и «во что», — а между ними кнопка обмена.
///
/// Собран строками, а не двумя колонками рядом: колонка ростом со своё
/// содержимое перекашивает соседнюю, стоит под одним из полей появиться лишней
/// строке. Строками единицы стоят на одной высоте с единицами, числа с
/// числами, и сообщение об ошибке не двигает то, что над ним.
class ConverterInputs extends StatelessWidget {
  const ConverterInputs({
    required this.state,
    required this.left,
    required this.right,
    required this.onCategory,
    required this.onUnit,
    required this.onSwap,
    required this.onValue,
    super.key,
  });

  final ConverterState state;
  final TextEditingController left;
  final TextEditingController right;
  final ValueChanged<UnitCategory> onCategory;
  final void Function(ConverterSide side, String unitId) onUnit;
  final VoidCallback onSwap;
  final void Function(ConverterSide side, String raw) onValue;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConverterCategoryField(
          category: state.category,
          onCategory: onCategory,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _unitField(ConverterSide.left, strings.from)),
            const SizedBox(width: _swapSlot),
            Expanded(child: _unitField(ConverterSide.right, strings.to)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _valueField(context, ConverterSide.left, left)),
            SizedBox(
              width: _swapSlot,
              height: _fieldHeight,
              child: Center(
                child: IconButton(
                  key: const ValueKey('converter_swap'),
                  tooltip: '${strings.from} / ${strings.to}',
                  onPressed: onSwap,
                  icon: const Icon(Icons.swap_horiz_rounded),
                ),
              ),
            ),
            Expanded(child: _valueField(context, ConverterSide.right, right)),
          ],
        ),
      ],
    );
  }

  Widget _unitField(ConverterSide side, String label) {
    final unitId = state.unitIdOf(side);
    return DropdownButtonFormField<String>(
      key: ValueKey('converter_${side.name}_${state.category.name}_$unitId'),
      initialValue: unitId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final item in state.units)
          DropdownMenuItem(
            value: item.id,
            child: Text(item.symbol, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (next) {
        if (next != null) onUnit(side, next);
      },
    );
  }

  Widget _valueField(
    BuildContext context,
    ConverterSide side,
    TextEditingController controller,
  ) {
    final unit = UnitConverter.unitOrNull(state.category, state.unitIdOf(side));
    // Цифровая клавиатура без косой черты не дала бы набрать «3/4», поэтому
    // единица, которую читают дробью, просит обычную клавиатуру.
    final fraction = unit?.display == UnitDisplay.inchFraction;
    final unreadable = side == state.entry &&
        state.raw.trim().isNotEmpty &&
        state.typed == null;
    return TextField(
      key: ValueKey('converter_value_${side.name}'),
      controller: controller,
      onChanged: (text) => onValue(side, text),
      keyboardType: fraction
          ? TextInputType.text
          : const TextInputType.numberWithOptions(decimal: true),
      style: Theme.of(context).textTheme.titleMedium,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        errorText: unreadable ? AppStrings.of(context).invalidNumber : null,
        errorMaxLines: 3,
      ),
    );
  }
}
