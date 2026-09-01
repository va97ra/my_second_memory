import 'package:flutter/material.dart';

/// Выбор одного варианта из нескольких.
///
/// Именно выбор, а не переключатель «да/нет»: у медной и алюминиевой жилы
/// нет главной и второстепенной, и выключенное состояние тумблера не умеет
/// назвать себя словом.
class EngineeringChoice<T> extends StatelessWidget {
  const EngineeringChoice({
    required this.value,
    required this.options,
    required this.onChanged,
    this.label,
    super.key,
  });

  final T value;

  /// Значение и его подпись — в том порядке, в каком их показывать.
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: theme.textTheme.bodySmall),
          const SizedBox(height: 6),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (option, title) in options)
              ChoiceChip(
                label: Text(title),
                selected: option == value,
                onSelected: (_) => onChanged(option),
              ),
          ],
        ),
      ],
    );
  }
}
