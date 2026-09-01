import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tool_data/tool_data.dart';
import '../../state/converter_controller.dart';

Future<void> saveConversion(
  BuildContext context,
  WidgetRef ref,
  ConverterState state,
) async {
  // В расчёт уходит число левой колонки: сохранённая запись хранит его в
  // единице `fromUnit`, и набор справа не должен менять смысл записи.
  final value = state.reading(ConverterSide.left)?.value;
  if (value == null) return;
  final name = await askCalculationName(context);
  if (name == null || !context.mounted) return;
  final now = DateTime.now();
  await ref.read(toolDataControllerProvider.notifier).saveCalculation(
        SavedToolCalculation(
          id: 'conversion-${now.microsecondsSinceEpoch}',
          name: name,
          payload: SavedConversionPayload(
            category: state.category.name,
            fromUnit: state.from,
            toUnit: state.to,
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
      UnitCategory.density => strings.density,
      UnitCategory.temperature => strings.temperature,
      UnitCategory.pressure => strings.pressure,
      UnitCategory.speed => strings.speed,
      UnitCategory.flow => strings.flow,
      UnitCategory.power => strings.power,
      UnitCategory.energy => strings.energy,
      UnitCategory.torque => strings.torque,
      UnitCategory.time => strings.time,
      UnitCategory.angle => strings.angle,
      UnitCategory.data => strings.dataSize,
      UnitCategory.voltage => strings.voltage,
      UnitCategory.current => strings.current,
      UnitCategory.resistance => strings.resistance,
      UnitCategory.frequency => strings.frequency,
    };

/// Обозначение единицы или её ключ, если такой единицы в таблице больше нет.
///
/// Ключ вместо обозначения читается плохо, но запись, сохранённую другой
/// версией, показать всё равно нужно — иначе список расчётов теряет строку.
String unitSymbol(String categoryName, String unitId) {
  for (final category in UnitCategory.values) {
    if (category.name != categoryName) continue;
    return UnitConverter.unitOrNull(category, unitId)?.symbol ?? unitId;
  }
  return unitId;
}
