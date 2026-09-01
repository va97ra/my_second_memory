import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

class ToolPageFrame extends StatelessWidget {
  const ToolPageFrame({
    required this.child,
    this.maxWidth = 760,
    super.key,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => WarmGradientBackground(
        child: Material(
          type: MaterialType.transparency,
          child: SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: child,
              ),
            ),
          ),
        ),
      );
}

class ToolNumberField extends StatelessWidget {
  const ToolNumberField({
    required this.controller,
    required this.label,
    this.suffix,
    this.hint,
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String? suffix;

  /// Короткая подсказка под полем: что сюда вводят и откуда берут.
  final String? hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          helperText: hint,
          helperMaxLines: 3,
          border: const OutlineInputBorder(),
        ),
      );
}

class ToolResultCard extends StatelessWidget {
  const ToolResultCard({
    required this.value,
    this.details = const [],
    super.key,
  });

  final String value;
  final List<String> details;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(strings.result, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SelectableText(
              value,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            for (final detail in details) ...[
              const SizedBox(height: 4),
              Text(detail),
            ],
          ],
        ),
      ),
    );
  }
}

Future<String?> askCalculationName(BuildContext context, {String? initial}) {
  final strings = AppStrings.of(context);
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(strings.saveCalculation),
      content: TextField(
        controller: controller,
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
          onPressed: () {
            final value = controller.text.trim();
            if (value.isNotEmpty) Navigator.pop(context, value);
          },
          child: Text(strings.save),
        ),
      ],
    ),
  ).whenComplete(controller.dispose);
}
