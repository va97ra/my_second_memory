import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import 'shift_vacation_dialog_fields.dart';

/// Диалог нового отпуска: дата начала и число календарных дней.
///
/// Возвращает [ShiftVacation] или `null`, если человек отказался.
class ShiftVacationEditorDialog extends StatefulWidget {
  const ShiftVacationEditorDialog({
    super.key,
    required this.existingVacations,
  });

  final List<ShiftVacation> existingVacations;

  @override
  State<ShiftVacationEditorDialog> createState() =>
      _ShiftVacationEditorDialogState();
}

class _ShiftVacationEditorDialogState extends State<ShiftVacationEditorDialog> {
  late final TextEditingController _durationController;
  late DateTime _startDate;
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _durationController = TextEditingController(text: '14');
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return AlertDialog(
      title: Text(strings.addVacation),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: ShiftVacationDialogFields(
            startDate: _startDate,
            durationController: _durationController,
            locale: Localizations.localeOf(context).languageCode,
            validationMessage: _validationMessage,
            onPickStartDate: _pickStartDate,
            onDurationChanged: () => setState(() => _validationMessage = null),
            onSubmit: _submit,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.cancel),
        ),
        FilledButton(
          key: const ValueKey('save_shift_vacation'),
          onPressed: _submit,
          child: Text(strings.add),
        ),
      ],
    );
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked != null && mounted) {
      setState(() {
        _startDate = DateTime(picked.year, picked.month, picked.day);
        _validationMessage = null;
      });
    }
  }

  /// Отпуск не может пересечься с уже заведённым: два отпуска на один день
  /// сделали бы рабочий день и выходным, и рабочим одновременно.
  void _submit() {
    final strings = AppStrings.of(context);
    final duration = int.tryParse(_durationController.text.trim());
    if (duration == null || duration <= 0) {
      setState(() => _validationMessage = strings.vacationInvalidDuration);
      return;
    }
    final vacation = ShiftVacation(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      startDate: _startDate,
      durationDays: duration,
    );
    if (widget.existingVacations.any(vacation.overlaps)) {
      setState(() => _validationMessage = strings.vacationOverlap);
      return;
    }
    Navigator.of(context).pop(vacation);
  }
}
