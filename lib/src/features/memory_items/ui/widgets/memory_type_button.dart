import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import '../../../../shared/ui/memory_card/memory_item_presentation.dart';
import 'type_picker_sheet.dart';

/// Вид записи — кнопкой в шапке, а не строкой формы: он у записи один и
/// меняется редко, а место занимал постоянно. У записки вид тоже есть и
/// виден в ленте, поэтому кнопка нужна и ей.
class MemoryTypeButton extends StatelessWidget {
  const MemoryTypeButton({
    required this.type,
    required this.onChanged,
    super.key,
  });

  final MemoryType type;
  final ValueChanged<MemoryType> onChanged;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const ValueKey('memory_type_picker'),
      tooltip: AppStrings.of(context).recordType,
      iconSize: 22,
      style: notebookIconButtonStyle(),
      onPressed: () => _pick(context),
      icon: Icon(memoryTypeIcon(type), color: memoryTypeColor(type)),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final selected = await showMemoryTypePicker(context, selected: type);
    if (selected != null) onChanged(selected);
  }
}
