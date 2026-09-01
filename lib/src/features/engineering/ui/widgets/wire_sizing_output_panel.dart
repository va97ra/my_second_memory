import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import '../../../tool_data/tool_data.dart';

class WireSizingOutputPanel extends StatelessWidget {
  const WireSizingOutputPanel({
    required this.current,
    required this.material,
    required this.routing,
    super.key,
  });

  final String current;
  final ConductorMaterial material;
  final WireRouting routing;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final currentA = parseToolNumber(current);
    if (currentA == null || currentA <= 0) {
      return ToolResultCard(value: strings.invalidNumber);
    }
    final result = selectWireSection(
      currentA: currentA,
      material: material,
      routing: routing,
    );
    if (result == null) {
      return ToolResultCard(value: strings.wireSizingNoResult);
    }
    final ru = strings.isRu;
    final unitA = EngUnit.ampere.symbol(ru);
    final marginPercent = (result.margin - 1) * 100;
    return ToolResultCard(
      value: formatEngValue(result.sectionMm2, EngUnit.millimetreSquared, ru),
      details: [
        '${strings.allowableCurrent}: '
            '${formatEngValue(result.allowableCurrentA, EngUnit.ampere, ru)}',
        '${strings.recommendedBreaker}: '
            '${result.breakerA == null ? '—' : '${result.breakerA} $unitA'}',
        '${strings.currentMargin}: '
            '${formatToolNumber(marginPercent, precision: 1)} %',
      ],
    );
  }
}
