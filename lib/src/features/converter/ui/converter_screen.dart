import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

import '../../tool_data/tool_data.dart';
import 'widgets/converter_form.dart';

class ConverterScreen extends StatelessWidget {
  const ConverterScreen({super.key});

  @override
  Widget build(BuildContext context) => ToolPageFrame(
        child: Column(
          key: const ValueKey('converter_screen'),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.of(context).converter,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const Icon(Icons.swap_horiz_rounded),
                ],
              ),
            ),
            const Expanded(child: ConverterForm()),
          ],
        ),
      );
}
