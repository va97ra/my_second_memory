import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Название организации и дата, с которой график начинает считаться.
class ShiftMainSettingsFields extends StatelessWidget {
  const ShiftMainSettingsFields({
    super.key,
    required this.organizationController,
    required this.startDate,
    required this.locale,
    required this.onStartDateChanged,
  });

  final TextEditingController organizationController;
  final DateTime startDate;
  final String locale;
  final ValueChanged<DateTime> onStartDateChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 52,
          child: TextFormField(
            controller: organizationController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: strings.organization,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () => _pickStartDate(context),
            icon: const Icon(Icons.today_rounded, size: 20),
            label: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${strings.startDate}: '
                '${DateFormat.yMMMd(locale).format(startDate)}',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && context.mounted) {
      onStartDateChanged(picked);
    }
  }
}
