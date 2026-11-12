import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import 'shift_days_field.dart';
import 'shift_preset_button.dart';

/// Рисунок графика: готовые варианты и свой.
///
/// Поля своего рисунка спрятаны, пока выбран готовый: два способа задать
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
            for (final preset in shiftPresets) ...[
              Expanded(
                child: ShiftPresetButton(
                  label: preset.label(locale),
                  isSelected: selectedPresetKey == preset.key,
                  onTap: () => onPreset(preset),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: ShiftPresetButton(
                key: const ValueKey('shift_custom_pattern'),
                label: strings.customSchedule,
                isSelected: showManualSchedule,
                onTap: onToggleManual,
              ),
            ),
          ],
        ),
        if (showManualSchedule) ...[
          const SizedBox(height: 12),
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
