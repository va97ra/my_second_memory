import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tool_data/tool_data.dart';

Future<void> saveConversion(
  BuildContext context,
  WidgetRef ref, {
  required UnitCategory category,
  required String from,
  required String to,
  required double value,
}) async {
  final name = await askCalculationName(context);
  if (name == null || !context.mounted) return;
  final now = DateTime.now();
  await ref.read(toolDataControllerProvider.notifier).saveCalculation(
        SavedToolCalculation(
          id: 'conversion-${now.microsecondsSinceEpoch}',
          name: name,
          payload: SavedConversionPayload(
            category: category.name,
            fromUnit: from,
            toUnit: to,
            value: value,
          ),
          createdAt: now,
          updatedAt: now,
        ),
      );
}

String categoryLabel(UnitCategory category, AppStrings strings) =>
    switch (category) {
      UnitCategory.length => strings.length,
      UnitCategory.area => strings.area,
      UnitCategory.volume => strings.volume,
      UnitCategory.mass => strings.mass,
      UnitCategory.temperature => strings.temperature,
      UnitCategory.pressure => strings.pressure,
      UnitCategory.speed => strings.speed,
      UnitCategory.flow => strings.flow,
      UnitCategory.power => strings.power,
      UnitCategory.energy => strings.energy,
      UnitCategory.data => strings.dataSize,
      UnitCategory.voltage => strings.voltage,
      UnitCategory.current => strings.current,
      UnitCategory.resistance => strings.resistance,
      UnitCategory.frequency => strings.frequency,
    };
