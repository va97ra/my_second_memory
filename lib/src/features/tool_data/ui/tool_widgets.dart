import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import 'calculation_name_dialog.dart';

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
  return showDialog<String>(
    context: context,
    builder: (context) => CalculationNameDialog(initial: initial),
  );
}
