import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tool_data/tool_data.dart';
import 'engineering_helpers.dart';
import 'plumbing_mode.dart';

class PlumbingOutputPanel extends ConsumerWidget {
  const PlumbingOutputPanel(
      {required this.mode,
      required this.flow,
      required this.diameter,
      required this.third,
      required this.head,
      required this.roughness,
      required this.power,
      required this.deltaTemperature,
      required this.slope,
      super.key});

  final PlumbingMode mode;
  final String flow, diameter, third, head, roughness;
  final String power, deltaTemperature, slope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flowLMin = parseToolNumber(flow),
        diameterMm = parseToolNumber(diameter),
        thirdValue = parseToolNumber(third);
    final strings = AppStrings.of(context);
    final ru = strings.isRu;
    try {
      if (mode == PlumbingMode.heating) {
        final powerKw = parseToolNumber(power);
        final delta = parseToolNumber(deltaTemperature);
        if (powerKw == null || delta == null) throw const FormatException();
        final heatingFlow = waterFlowForHeatM3s(
            powerW: powerKw * 1000, deltaTemperatureK: delta);
        return _output(
            context,
            ref,
            formatEngValue(heatingFlow * 60000, EngUnit.litrePerMinute, ru),
            'heatingFlow',
            {'powerKw': powerKw, 'deltaTemperatureK': delta},
            [
              '${strings.flow}: '
                  '${formatEngValue(heatingFlow * 3600, EngUnit.cubicMetrePerHour, ru)}'
            ]);
      }
      if (mode == PlumbingMode.slope) {
        final slopePercent = parseToolNumber(slope);
        if (slopePercent == null || thirdValue == null) {
          throw const FormatException();
        }
        final fall = slopeFallM(slope: slopePercent / 100, lengthM: thirdValue);
        return _output(
            context,
            ref,
            formatEngValue(fall * 1000, EngUnit.millimetre, ru),
            'slopeFall',
            {'slopePercent': slopePercent, 'lengthM': thirdValue},
            [
              '${strings.fallPerMetre}: '
                  '${formatEngValue(slopePercent * 10, EngUnit.millimetre, ru)}'
            ]);
      }
      if (flowLMin == null || diameterMm == null || thirdValue == null) {
        throw const FormatException();
      }
      final flowM3s = flowLMin / 60000, diameterM = diameterMm / 1000;
      if (mode == PlumbingMode.flow) {
        final actual = EngineeringCalculations.circularFlow(
            flowM3s: flowM3s, diameterM: diameterM);
        final recommended = EngineeringCalculations.diameterForFlow(
            flowM3s: flowM3s, targetVelocityMs: thirdValue);
        return _output(context, ref,
            formatEngValue(actual.velocityMs, EngUnit.metrePerSecond, ru),
            'flow', {
          'flowLMin': flowLMin,
          'diameterMm': diameterMm,
          'targetVelocityMs': thirdValue
        }, [
          '${strings.diameterAtTargetVelocity}: '
              '${formatEngValue(recommended * 1000, EngUnit.millimetre, ru)}'
        ]);
      }
      final volume = EngineeringCalculations.pipeVolumeM3(
          internalDiameterM: diameterM, lengthM: thirdValue);
      final fill = EngineeringCalculations.fillTimeSeconds(
          volumeM3: volume, flowM3s: flowM3s);
      if (mode == PlumbingMode.volume) {
        return _output(context, ref, formatEngValue(volume * 1000, EngUnit.litre, ru),
            'pipeVolume', {
          'flowLMin': flowLMin,
          'diameterMm': diameterMm,
          'lengthM': thirdValue
        }, [
          '${strings.fillTime}: ${formatEngValue(fill, EngUnit.second, ru)}'
        ]);
      }
      final headM = parseToolNumber(head),
          roughnessMm = parseToolNumber(roughness);
      if (headM == null || roughnessMm == null) throw const FormatException();
      final pressure = EngineeringCalculations.pressureFromWaterHead(headM);
      final loss = EngineeringCalculations.waterPressureLoss(
          flowM3s: flowM3s,
          diameterM: diameterM,
          lengthM: thirdValue,
          roughnessM: roughnessMm / 1000);
      return _output(context, ref, formatEngValue(pressure / 100000, EngUnit.bar, ru),
          'pressureLoss', {
        'flowLMin': flowLMin,
        'diameterMm': diameterMm,
        'lengthM': thirdValue,
        'headM': headM,
        'roughnessMm': roughnessMm
      }, [
        '${strings.linearLoss}: '
            '${formatEngValue(loss.lossPaPerM, EngUnit.pascalPerMetre, ru)}',
        '${strings.totalLoss}: '
            '${formatEngValue(loss.lossPa, EngUnit.pascal, ru)}'
      ]);
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
                    discipline: 'plumbing',
                    calculator: calculator,
                    values: values),
                icon: const Icon(Icons.bookmark_add_outlined),
                label: Text(AppStrings.of(context).saveCalculation))),
      ]);
}
