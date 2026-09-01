import 'package:ez_core/ez_core.dart';
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

/// Подпись способа прокладки. Нужна и подбору сечения, и падению напряжения.
String wireRoutingLabel(AppStrings strings, WireRouting routing) =>
    switch (routing) {
      WireRouting.openAir => strings.wireRoutingOpen,
      WireRouting.conduitTwo => strings.wireRoutingConduitTwo,
      WireRouting.conduitThree => strings.wireRoutingConduitThree,
    };

/// Стандартные напряжения сети.
const singlePhaseVoltage = '230';
const threePhaseVoltage = '400';

/// Напряжение после смены числа фаз.
///
/// Стандартное меняется вместе с сетью, введённое руками остаётся: прежний
/// экран подставлял 400 В и не возвращал 230, и однофазный расчёт молча шёл
/// от чужого напряжения.
String voltageForPhases({required String text, required bool threePhase}) {
  final previous = threePhase ? singlePhaseVoltage : threePhaseVoltage;
  if (text.trim() != previous) return text;
  return threePhase ? threePhaseVoltage : singlePhaseVoltage;
}
