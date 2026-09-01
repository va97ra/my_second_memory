import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import '../../../tool_data/tool_data.dart';
import 'engineering_choice.dart';
import 'engineering_helpers.dart';
import 'engineering_input_grid.dart';
import 'engineering_section.dart';

/// Блок «Линия»: из чего сделана жила, какая она и как проложена.
class VoltageDropLineSection extends StatelessWidget {
  const VoltageDropLineSection({
    required this.material,
    required this.routing,
    required this.sectionMm2,
    required this.length,
    required this.onMaterialChanged,
    required this.onRoutingChanged,
    required this.onSectionChanged,
    required this.onLengthChanged,
    super.key,
  });

  final ConductorMaterial material;
  final WireRouting routing;
  final double sectionMm2;
  final TextEditingController length;
  final ValueChanged<ConductorMaterial> onMaterialChanged;
  final ValueChanged<WireRouting> onRoutingChanged;
  final ValueChanged<double> onSectionChanged;
  final VoidCallback onLengthChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final ru = strings.isRu;
    return EngineeringSection(
      title: strings.lineSection,
      children: [
        EngineeringChoice<ConductorMaterial>(
          label: strings.conductorMaterial,
          value: material,
          options: [
            (ConductorMaterial.copper, strings.copper),
            (ConductorMaterial.aluminium, strings.aluminium),
          ],
          onChanged: onMaterialChanged,
        ),
        const SizedBox(height: 12),
        EngineeringInputGrid(
          children: [
            DropdownButtonFormField<double>(
              key: ValueKey(sectionMm2),
              initialValue: sectionMm2,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: strings.conductorSection,
                suffixText: EngUnit.millimetreSquared.symbol(ru),
                helperText: strings.hintSection,
              ),
              items: [
                for (final section in standardSectionsMm2)
                  DropdownMenuItem(
                    value: section,
                    child: Text(formatToolNumber(section, precision: 1)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) onSectionChanged(value);
              },
            ),
            ToolNumberField(
              controller: length,
              label: strings.oneWayLength,
              suffix: EngUnit.metre.symbol(ru),
              hint: strings.hintOneWayLength,
              onChanged: (_) => onLengthChanged(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<WireRouting>(
          key: ValueKey(routing),
          initialValue: routing,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: strings.wireRouting,
            helperText: strings.hintRouting,
            helperMaxLines: 3,
          ),
          items: [
            for (final value in WireRouting.values)
              DropdownMenuItem(
                value: value,
                child: Text(wireRoutingLabel(strings, value)),
              ),
          ],
          onChanged: (value) {
            if (value != null) onRoutingChanged(value);
          },
        ),
      ],
    );
  }
}
