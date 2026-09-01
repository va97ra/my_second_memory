import 'package:flutter/material.dart';

class EngineeringInputGrid extends StatelessWidget {
  const EngineeringInputGrid({
    required this.children,
    super.key,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          const gap = 8.0;
          const minimumFieldWidth = 136.0;
          final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
          final columnWidth = (constraints.maxWidth - gap) / 2;
          final useTwoColumns =
              columnWidth >= minimumFieldWidth && textScale <= 1.5;

          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (var index = 0; index < children.length; index++)
                SizedBox(
                  width: useTwoColumns &&
                          !(children.length.isOdd &&
                              index == children.length - 1)
                      ? columnWidth
                      : constraints.maxWidth,
                  child: children[index],
                ),
            ],
          );
        },
      );
}
