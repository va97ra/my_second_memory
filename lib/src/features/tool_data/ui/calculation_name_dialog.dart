import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

class CalculationNameDialog extends StatefulWidget {
  const CalculationNameDialog({this.initial, super.key});

  final String? initial;

  @override
  State<CalculationNameDialog> createState() => _CalculationNameDialogState();
}

class _CalculationNameDialogState extends State<CalculationNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return AlertDialog(
      title: Text(strings.saveCalculation),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 80,
        decoration: InputDecoration(labelText: strings.calculationName),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(strings.save),
        ),
      ],
    );
  }

  void _save() {
    final value = _controller.text.trim();
    if (value.isNotEmpty) Navigator.pop(context, value);
  }
}
