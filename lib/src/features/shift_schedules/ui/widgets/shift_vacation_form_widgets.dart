part of '../shift_schedules_screen.dart';

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _VacationListEditor extends StatelessWidget {
  const _VacationListEditor({
    required this.vacations,
    required this.locale,
    required this.onAdd,
    required this.onRemove,
  });

  final List<ShiftVacation> vacations;
  final String locale;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (vacations.isEmpty)
          Container(
            key: const ValueKey('shift_vacations_empty'),
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.beach_access_rounded,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    strings.noVacations,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          )
        else
          for (var index = 0; index < vacations.length; index++) ...[
            if (index > 0) const SizedBox(height: 8),
            _VacationPeriodTile(
              vacation: vacations[index],
              locale: locale,
              onRemove: () => onRemove(vacations[index].id),
            ),
          ],
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            key: const ValueKey('add_shift_vacation'),
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: Text(strings.addVacation),
          ),
        ),
      ],
    );
  }
}

class _VacationPeriodTile extends StatelessWidget {
  const _VacationPeriodTile({
    required this.vacation,
    required this.locale,
    required this.onRemove,
  });

  final ShiftVacation vacation;
  final String locale;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = Theme.of(context).colorScheme;
    final start = DateFormat.yMMMd(locale).format(vacation.startDate);
    final end = DateFormat.yMMMd(locale).format(vacation.endDate);

    return Container(
      key: ValueKey('shift_vacation_${vacation.id}'),
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.only(left: 12, right: 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF891C37),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD6A84B)),
            ),
            child: const SizedBox(
              width: 36,
              height: 36,
              child: Icon(
                Icons.beach_access_rounded,
                size: 20,
                color: Color(0xFFFFE5A3),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$start — $end',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  strings.vacationDays(vacation.durationDays),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            key: ValueKey('remove_shift_vacation_${vacation.id}'),
            tooltip: strings.delete,
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _VacationEditorDialog extends StatefulWidget {
  const _VacationEditorDialog({required this.existingVacations});

  final List<ShiftVacation> existingVacations;

  @override
  State<_VacationEditorDialog> createState() => _VacationEditorDialogState();
}

class _VacationEditorDialogState extends State<_VacationEditorDialog> {
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
    final locale = Localizations.localeOf(context).languageCode;
    final duration = int.tryParse(_durationController.text.trim());
    final endDate = duration != null && duration > 0
        ? _startDate.add(Duration(days: duration - 1))
        : null;

    return AlertDialog(
      title: Text(strings.addVacation),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
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
                  onPressed: _pickStartDate,
                  icon: const Icon(Icons.date_range_rounded),
                  label: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      DateFormat.yMMMd(locale).format(_startDate),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('vacation_duration_days'),
                controller: _durationController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() => _validationMessage = null),
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: strings.vacationDuration,
                  filled: true,
                  fillColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 12),
              if (endDate != null)
                Text(
                  '${DateFormat.yMMMd(locale).format(_startDate)} — '
                  '${DateFormat.yMMMd(locale).format(endDate)}',
                  key: const ValueKey('vacation_end_date_preview'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              if (_validationMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _validationMessage!,
                  key: const ValueKey('vacation_validation_error'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ],
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
