import 'package:flutter/material.dart';

/// Поле ручного ввода числа дней — рабочих или выходных.
class ShiftDaysField extends StatelessWidget {
  const ShiftDaysField({
    super.key,
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      onChanged: (_) => onChanged(),
    );
  }
}
