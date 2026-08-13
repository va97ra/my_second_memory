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

class _PresetButton extends StatelessWidget {
  const _PresetButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.14)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              Icon(
                Icons.check_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSwitchRow extends StatelessWidget {
  const _SettingsSwitchRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.only(left: 12, right: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: notebookSurfaceShadow(
          context,
          NotebookSurfaceDepth.card,
        ),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _AlarmEditorCard extends StatelessWidget {
  const _AlarmEditorCard({
    required this.title,
    required this.subtitle,
    required this.alarm,
    required this.systemSoundLabel,
    required this.timeLabel,
    required this.soundLabel,
    required this.onToggle,
    required this.onPickTime,
    required this.onPickSound,
  });

  final String title;
  final String subtitle;
  final ShiftAlarm alarm;
  final String systemSoundLabel;
  final String timeLabel;
  final String soundLabel;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickTime;
  final VoidCallback onPickSound;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Row(
                children: [
                  Icon(
                    Icons.alarm_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Switch(value: alarm.isEnabled, onChanged: onToggle),
                ],
              ),
            ),
          ),
          if (alarm.isEnabled) ...[
            const Divider(height: 1, indent: 12, endIndent: 12),
            _AlarmActionRow(
              icon: Icons.schedule_rounded,
              title: timeLabel,
              value: _formatMinutes(alarm.timeMinutes),
              onTap: onPickTime,
            ),
            const Divider(height: 1, indent: 44, endIndent: 12),
            _AlarmActionRow(
              icon: Icons.music_note_rounded,
              title: soundLabel,
              value: alarm.soundName ?? systemSoundLabel,
              onTap: onPickSound,
            ),
          ],
        ],
      ),
    );
  }
}

class _AlarmActionRow extends StatelessWidget {
  const _AlarmActionRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShiftColorPicker extends StatefulWidget {
  const _ShiftColorPicker({
    required this.color,
    required this.onChanged,
  });

  final Color color;
  final ValueChanged<Color> onChanged;

  @override
  State<_ShiftColorPicker> createState() => _ShiftColorPickerState();
}

class _ShiftColorPickerState extends State<_ShiftColorPicker> {
  static const _baseSaturation = 0.82;
  static const _baseValue = 0.92;

  late double _hue;
  late double _tone;
  late Color _currentColor;
  int? _lastEmittedColor;

  @override
  void initState() {
    super.initState();
    _syncFromColor(widget.color);
  }

  @override
  void didUpdateWidget(covariant _ShiftColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextColor = widget.color.toARGB32();
    if (nextColor != _lastEmittedColor &&
        nextColor != oldWidget.color.toARGB32()) {
      _syncFromColor(widget.color);
    }
  }

  void _syncFromColor(Color color) {
    _currentColor = color;
    final hsv = HSVColor.fromColor(color);
    _hue = hsv.saturation < 0.02 ? 0 : hsv.hue;
    if (hsv.value >= _baseValue) {
      final lightProgress =
          _unit((hsv.saturation - 0.08) / (_baseSaturation - 0.08));
      _tone = lightProgress * 0.5;
    } else {
      final darkProgress =
          _unit((_baseValue - hsv.value) / (_baseValue - 0.24));
      _tone = 0.5 + darkProgress * 0.5;
    }
  }

  Color get _vividColor =>
      HSVColor.fromAHSV(1, _hue, _baseSaturation, _baseValue).toColor();

  Color _colorAtTone(double tone) {
    if (tone <= 0.5) {
      final progress = tone * 2;
      return HSVColor.fromAHSV(
        1,
        _hue,
        _lerp(0.08, _baseSaturation, progress),
        _lerp(1, _baseValue, progress),
      ).toColor();
    }
    final progress = (tone - 0.5) * 2;
    return HSVColor.fromAHSV(
      1,
      _hue,
      _lerp(_baseSaturation, 0.92, progress),
      _lerp(_baseValue, 0.24, progress),
    ).toColor();
  }

  void _setHue(double position) {
    setState(() {
      _hue = _unit(position) * 360;
      _currentColor = _colorAtTone(_tone);
    });
    _emitColor();
  }

  void _setTone(double position) {
    setState(() {
      _tone = _unit(position);
      _currentColor = _colorAtTone(_tone);
    });
    _emitColor();
  }

  void _emitColor() {
    final color = _currentColor;
    _lastEmittedColor = color.toARGB32();
    widget.onChanged(color);
  }

  @override
  Widget build(BuildContext context) {
    final color = _currentColor;
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).languageCode;
    final isRu = locale == 'ru';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: notebookSurfaceShadow(
          context,
          NotebookSurfaceDepth.card,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AnimatedContainer(
                  key: const ValueKey('shift_color_preview'),
                  duration: const Duration(milliseconds: 120),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.onSurface.withValues(alpha: 0.28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.32),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isRu ? 'Выбранный цвет' : 'Selected color',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _ColorGradientTrack(
              key: const ValueKey('shift_color_hue'),
              semanticLabel: isRu ? 'Оттенок цвета' : 'Color hue',
              value: _hue / 360,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF3333),
                  Color(0xFFFFFF33),
                  Color(0xFF33FF33),
                  Color(0xFF33FFFF),
                  Color(0xFF3333FF),
                  Color(0xFFFF33FF),
                  Color(0xFFFF3333),
                ],
              ),
              thumbColor: HSVColor.fromAHSV(1, _hue, 0.86, 0.96).toColor(),
              onChanged: _setHue,
              onDecrease: () => _setHue((_hue / 360) - 0.02),
              onIncrease: () => _setHue((_hue / 360) + 0.02),
            ),
            const SizedBox(height: 10),
            _ColorGradientTrack(
              key: const ValueKey('shift_color_tone'),
              semanticLabel: isRu ? 'Светлота цвета' : 'Color brightness',
              value: _tone,
              gradient: LinearGradient(
                colors: [
                  HSVColor.fromAHSV(1, _hue, 0.08, 1).toColor(),
                  _vividColor,
                  HSVColor.fromAHSV(1, _hue, 0.92, 0.24).toColor(),
                ],
                stops: const [0, 0.5, 1],
              ),
              thumbColor: color,
              onChanged: _setTone,
              onDecrease: () => _setTone(_tone - 0.04),
              onIncrease: () => _setTone(_tone + 0.04),
            ),
          ],
        ),
      ),
    );
  }

  static double _unit(double value) {
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }

  static double _lerp(double start, double end, double progress) =>
      start + (end - start) * progress;
}

class _ColorGradientTrack extends StatelessWidget {
  const _ColorGradientTrack({
    super.key,
    required this.semanticLabel,
    required this.value,
    required this.gradient,
    required this.thumbColor,
    required this.onChanged,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String semanticLabel;
  final double value;
  final LinearGradient gradient;
  final Color thumbColor;
  final ValueChanged<double> onChanged;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        void update(Offset localPosition) {
          onChanged(localPosition.dx / width);
        }

        return Semantics(
          label: semanticLabel,
          value: '${(value * 100).round()}%',
          decreasedValue: '${((value * 100).round() - 1).clamp(0, 100)}%',
          increasedValue: '${((value * 100).round() + 1).clamp(0, 100)}%',
          slider: true,
          onDecrease: onDecrease,
          onIncrease: onIncrease,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) => update(details.localPosition),
            onHorizontalDragStart: (details) => update(details.localPosition),
            onHorizontalDragUpdate: (details) => update(details.localPosition),
            child: SizedBox(
              height: 34,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    top: 4,
                    bottom: 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.24),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: (width - 22) * value,
                    top: 0,
                    child: Container(
                      width: 22,
                      height: 34,
                      decoration: BoxDecoration(
                        color: thumbColor,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x66000000),
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ShiftPreset {
  const _ShiftPreset(
    this.key,
    this.ruLabel,
    this.enLabel,
    this.workDays,
    this.restDays,
  );

  final String key;
  final String ruLabel;
  final String enLabel;
  final int workDays;
  final int restDays;

  String label(String locale) {
    return locale == 'ru' ? ruLabel : enLabel;
  }
}
