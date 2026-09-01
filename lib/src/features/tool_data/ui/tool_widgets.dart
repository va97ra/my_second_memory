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
