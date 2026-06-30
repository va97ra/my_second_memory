import 'package:flutter/material.dart';

import '../../domain/memory_type.dart';

class MemoryTypePicker extends StatelessWidget {
  const MemoryTypePicker({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final MemoryType selected;
  final ValueChanged<MemoryType> onSelected;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final type in MemoryType.values)
          ChoiceChip(
            label: Text(type.label(locale)),
            selected: selected == type,
            onSelected: (_) => onSelected(type),
          ),
      ],
    );
  }
}
