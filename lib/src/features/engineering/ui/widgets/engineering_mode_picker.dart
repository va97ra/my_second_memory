import 'package:flutter/material.dart';

/// Выбор расчёта одной строкой.
///
/// Раньше режимы стояли рядом кнопками. Пять кнопок на узком экране
/// переносились в три ряда и съедали верх страницы — а выбор делают один раз
/// и дальше на него не смотрят. Поэтому список раскрывается по нажатию, а на
/// экране остаётся строка с текущим расчётом.
class EngineeringModePicker<T> extends StatelessWidget {
  const EngineeringModePicker({
    required this.value,
    required this.options,
    required this.onChanged,
    super.key,
  });

  final T value;

  /// Значение и его подпись — в том порядке, в каком их показывать.
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = options
        .firstWhere((option) => option.$1 == value, orElse: () => options.first)
        .$2;
    return PopupMenuButton<T>(
      initialValue: value,
      tooltip: title,
      onSelected: onChanged,
      position: PopupMenuPosition.under,
      itemBuilder: (context) => [
        for (final (option, label) in options)
          PopupMenuItem(
            value: option,
            child: Row(
              children: [
                Icon(
                  option == value
                      ? Icons.check_rounded
                      : Icons.check_box_outline_blank_rounded,
                  size: 18,
                  color: option == value
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                ),
                const SizedBox(width: 12),
                Flexible(child: Text(label)),
              ],
            ),
          ),
      ],
      child: InputDecorator(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(title, style: theme.textTheme.titleMedium),
            ),
            const Icon(Icons.arrow_drop_down_rounded),
          ],
        ),
      ),
    );
  }
}
