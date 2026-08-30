import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tool_data/tool_data.dart';
import 'engineering_helpers.dart';
import 'ventilation_mode.dart';

class VentilationOutputPanel extends ConsumerWidget {
  const VentilationOutputPanel(
      {required this.mode,
      required this.flow,
      required this.width,
      required this.height,
      required this.velocity,
      required this.roomLength,
      required this.roomWidth,
      required this.roomHeight,
      required this.ach,
      super.key});

  final VentilationMode mode;
  final String flow, width, height, velocity;
  final String roomLength, roomWidth, roomHeight, ach;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final ru = strings.isRu;
    try {
      if (mode == VentilationMode.duct) {
        final flowM3h = parseToolNumber(flow),
            widthMm = parseToolNumber(width),
            heightMm = parseToolNumber(height),
            target = parseToolNumber(velocity);
        if (flowM3h == null ||
            widthMm == null ||
            heightMm == null ||
            target == null) {
          throw const FormatException();
        }
        final result = EngineeringCalculations.rectangularDuct(
            flowM3s: flowM3h / 3600,
            widthM: widthMm / 1000,
            heightM: heightMm / 1000);
        final round = EngineeringCalculations.diameterForFlow(
            flowM3s: flowM3h / 3600, targetVelocityMs: target);
        return _output(context, ref,
            '${formatToolNumber(result.velocityMs)} ${EngUnit.metrePerSecond.symbol(ru)}',
            'duct', {
          'flowM3h': flowM3h,
          'widthMm': widthMm,
          'heightMm': heightMm,
          'targetVelocityMs': target
        }, [
          '${strings.area}: '
              '${formatToolNumber(result.areaM2)} ${EngUnit.metreSquared.symbol(ru)}',
          '${strings.equivalentDiameter}: '
              '${formatToolNumber(result.equivalentDiameterM * 1000)} ${EngUnit.millimetre.symbol(ru)}',
          '${strings.roundAtTargetVelocity}: '
              '${formatToolNumber(round * 1000)} ${EngUnit.millimetre.symbol(ru)}',
        ]);
      }
      final lengthM = parseToolNumber(roomLength),
          widthM = parseToolNumber(roomWidth),
          heightM = parseToolNumber(roomHeight),
          changes = parseToolNumber(ach);
      if (lengthM == null ||
          widthM == null ||
          heightM == null ||
          changes == null) {
        throw const FormatException();
      }
      final airflow = EngineeringCalculations.airFlowForRoom(
          lengthM: lengthM,
          widthM: widthM,
          heightM: heightM,
          airChangesPerHour: changes);
      return _output(
          context, ref, '${formatToolNumber(airflow)} ${EngUnit.cubicMetrePerHour.symbol(ru)}',
          'airExchange', {
        'lengthM': lengthM,
        'widthM': widthM,
        'heightM': heightM,
        'airChangesPerHour': changes
      }, const []);
    } catch (_) {
      return ToolResultCard(value: AppStrings.of(context).invalidNumber);
    }
  }

  Widget _output(
          BuildContext context,
          WidgetRef ref,
          String result,
          String calculator,
          Map<String, double> values,
          List<String> details) =>
      Column(children: [
        ToolResultCard(value: result, details: details),
        const SizedBox(height: 12),
        SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
                onPressed: () => saveEngineering(context, ref,
                    discipline: 'ventilation',
                    calculator: calculator,
                    values: values),
                icon: const Icon(Icons.bookmark_add_outlined),
                label: Text(AppStrings.of(context).saveCalculation))),
      ]);
}
