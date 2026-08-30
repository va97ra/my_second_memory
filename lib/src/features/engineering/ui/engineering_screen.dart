import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

import '../../tool_data/tool_data.dart';
import 'widgets/electrical_calculator.dart';
import 'widgets/engineering_saved_list.dart';
import 'widgets/plumbing_calculator.dart';
import 'widgets/ventilation_calculator.dart';

class EngineeringScreen extends StatelessWidget {
  const EngineeringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return ToolPageFrame(
      maxWidth: 840,
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            TabBar(
              key: const ValueKey('engineering_tabs'),
              isScrollable: MediaQuery.sizeOf(context).width < 420,
              tabAlignment: MediaQuery.sizeOf(context).width < 420
                  ? TabAlignment.start
                  : TabAlignment.fill,
              tabs: [
                Tab(
                    text: strings.electrical,
                    icon: const Icon(Icons.bolt_rounded)),
                Tab(
                    text: strings.plumbing,
                    icon: const Icon(Icons.water_drop_rounded)),
                Tab(
                    text: strings.ventilation,
                    icon: const Icon(Icons.air_rounded)),
              ],
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  ElectricalCalculator(),
                  PlumbingCalculator(),
                  VentilationCalculator(),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: EngineeringSavedList(),
            ),
          ],
        ),
      ),
    );
  }
}
