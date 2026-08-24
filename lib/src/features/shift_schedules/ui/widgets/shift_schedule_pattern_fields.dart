import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import 'shift_days_field.dart';
import 'shift_preset_button.dart';

/// Рисунок графика: готовые варианты и ручной ввод под ними.
///
/// Ручной ввод спрятан, пока рисунок совпадает с готовым: два способа задать
/// одно и то же, показанные разом, сбивают с толку.
class ShiftSchedulePatternFields extends StatelessWidget {
  const ShiftSchedulePatternFields({
    super.key,
    required this.selectedPresetKey,
    required this.showManualSchedule,
    required this.workDaysController,
    required this.restDaysController,
    required this.locale,
    required this.onPreset,
    required this.onToggleManual,
    required this.onDaysChanged,
  });

  final String? selectedPresetKey;
  final bool showManualSchedule;
  final TextEditingController workDaysController;
  final TextEditingController restDaysController;
  final String locale;
  final ValueChanged<ShiftPreset> onPreset;
  final VoidCallback onToggleManual;
  final VoidCallback onDaysChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var index = 0; index < shiftPresets.length; index++) ...[
              if (index > 0) const SizedBox(width: 8),
              Expanded(
                child: ShiftPresetButton(
                  label: shiftPresets[index].label(locale),
                  isSelected: selectedPresetKey == shiftPresets[index].key,
                  onTap: () => onPreset(shiftPresets[index]),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: onToggleManual,
          icon: Icon(
            showManualSchedule
                ? Icons.expand_less_rounded
                : Icons.tune_rounded,
          ),
          label: Align(
            alignment: Alignment.centerLeft,
            child: Text(strings.manualSchedule),
          ),
        ),
        if (showManualSchedule) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: ShiftDaysField(
                  controller: workDaysController,
                  label: strings.workDays,
                  onChanged: onDaysChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ShiftDaysField(
                  controller: restDaysController,
                  label: strings.restDays,
                  onChanged: onDaysChanged,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
