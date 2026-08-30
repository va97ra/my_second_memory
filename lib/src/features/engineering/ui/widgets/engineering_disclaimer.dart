import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

class EngineeringDisclaimer extends StatelessWidget {
  const EngineeringDisclaimer({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
        label: AppStrings.of(context).warning,
        child: Card(
          color: Theme.of(context).colorScheme.tertiaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(AppStrings.of(context).engineeringDisclaimer),
                ),
              ],
            ),
          ),
        ),
      );
}
