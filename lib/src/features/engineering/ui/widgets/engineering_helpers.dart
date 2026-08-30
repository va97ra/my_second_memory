import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tool_data/tool_data.dart';

Future<void> saveEngineering(
  BuildContext context,
  WidgetRef ref, {
  required String discipline,
  required String calculator,
  required Map<String, double> values,
}) async {
  final name = await askCalculationName(context);
  if (name == null || !context.mounted) return;
  final now = DateTime.now();
  await ref.read(toolDataControllerProvider.notifier).saveCalculation(
        SavedToolCalculation(
          id: 'engineering-${now.microsecondsSinceEpoch}',
          name: name,
          payload: SavedEngineeringPayload(
            discipline: discipline,
            calculator: calculator,
            values: values,
          ),
          createdAt: now,
          updatedAt: now,
        ),
      );
}

Widget engineeringModeSelector<T>({
  required T value,
  required List<ButtonSegment<T>> segments,
  required ValueChanged<T> onChanged,
}) =>
    SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<T>(
        segments: segments,
        selected: {value},
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
