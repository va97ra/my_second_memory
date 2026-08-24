import 'package:flutter/material.dart';

import 'shift_section_label.dart';

/// Раздел редактора: подпись, содержимое и отступ до следующего раздела.
///
/// Отступы заданы здесь одни на все разделы, иначе они разъезжаются по мере
/// того, как разделов становится больше.
class ShiftEditorSection extends StatelessWidget {
  const ShiftEditorSection({
    super.key,
    required this.label,
    required this.child,
    this.bottomGap = 12,
  });

  final String label;
  final Widget child;
  final double bottomGap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShiftSectionLabel(label),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
