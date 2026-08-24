import 'package:flutter/material.dart';

/// Вертикальная черта между действиями в панели метаданных.
class MetadataDivider extends StatelessWidget {
  const MetadataDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}
