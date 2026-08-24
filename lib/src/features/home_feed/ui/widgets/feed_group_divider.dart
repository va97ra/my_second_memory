import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Разделитель между днями внутри раскрытого периода.
class FeedGroupDivider extends StatelessWidget {
  const FeedGroupDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Center(
        child: AppLabeledDivider(
          label: label,
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }
}
