import 'package:flutter/material.dart';

class ConverterSaveButton extends StatelessWidget {
  const ConverterSaveButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      key: const ValueKey('converter_save'),
      onPressed: onPressed,
      icon: const Icon(Icons.bookmark_add_outlined),
      label: Text(label),
    );
  }
}
