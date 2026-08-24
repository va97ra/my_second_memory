import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Поля диалога отпуска: дата начала, число дней и что из них получилось.
class ShiftVacationDialogFields extends StatelessWidget {
  const ShiftVacationDialogFields({
    super.key,
    required this.startDate,
    required this.durationController,
    required this.locale,
    required this.validationMessage,
    required this.onPickStartDate,
    required this.onDurationChanged,
    required this.onSubmit,
  });

  final DateTime startDate;
  final TextEditingController durationController;
  final String locale;
  final String? validationMessage;
  final VoidCallback onPickStartDate;
  final VoidCallback onDurationChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final duration = int.tryParse(durationController.text.trim());
    final endDate = duration != null && duration > 0
        ? startDate.add(Duration(days: duration - 1))
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          strings.vacationStartDate,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            key: const ValueKey('vacation_start_date'),
            onPressed: onPickStartDate,
            icon: const Icon(Icons.date_range_rounded),
            label: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                DateFormat.yMMMd(locale).format(startDate),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('vacation_duration_days'),
          controller: durationController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onChanged: (_) => onDurationChanged(),
          onSubmitted: (_) => onSubmit(),
          decoration: InputDecoration(
            labelText: strings.vacationDuration,
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: 12),
        if (endDate != null)
          Text(
            '${DateFormat.yMMMd(locale).format(startDate)} — '
            '${DateFormat.yMMMd(locale).format(endDate)}',
            key: const ValueKey('vacation_end_date_preview'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
        if (validationMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            validationMessage!,
            key: const ValueKey('vacation_validation_error'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ],
    );
  }
}
