import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import 'converter_helpers.dart';

/// Выбор величины: длинная строка над обеими колонками.
///
/// Отдельно от полей пары нарочно: величина решает, какие единицы вообще
/// бывают, и меняет обе колонки сразу — это другое действие, чем выбрать
/// единицу или набрать число.
class ConverterCategoryField extends StatelessWidget {
  const ConverterCategoryField({
    required this.category,
    required this.onCategory,
    super.key,
  });

  final UnitCategory category;
  final ValueChanged<UnitCategory> onCategory;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return DropdownButtonFormField<UnitCategory>(
      // Ключ несёт текущее значение: `initialValue` читается один раз при
      // создании, и без смены ключа список не догонит выбор, сделанный мимо
      // него — например, открытием сохранённого расчёта.
      key: ValueKey('converter_category_${category.name}'),
      initialValue: category,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: strings.category,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final item in UnitCategory.values)
          DropdownMenuItem(
            value: item,
            child: Text(
              categoryLabel(item, strings),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (next) {
        if (next != null) onCategory(next);
      },
    );
  }
}
