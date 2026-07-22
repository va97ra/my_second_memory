part of '../shift_schedules_screen.dart';

class _ShiftScheduleEditorSheet extends ConsumerStatefulWidget {
  const _ShiftScheduleEditorSheet({this.schedule});

  final ShiftSchedule? schedule;

  @override
  ConsumerState<_ShiftScheduleEditorSheet> createState() =>
      _ShiftScheduleEditorSheetState();
}

class _ShiftScheduleEditorSheetState
    extends ConsumerState<_ShiftScheduleEditorSheet> {
  static const _colors = [
    Color(0xFF5B7FA3),
    Color(0xFF0891B2),
    Color(0xFF16A34A),
    Color(0xFFF59E0B),
    Color(0xFFEA580C),
    Color(0xFFDB2777),
    Color(0xFF7C3AED),
    Color(0xFFC2BFB6),
  ];

  static const _presets = [
    _ShiftPreset('5/2', '5/2', '5/2', 5, 2),
    _ShiftPreset('2/2', '2/2', '2/2', 2, 2),
    _ShiftPreset('1/3', 'сутки/трое', '24h/3 off', 1, 3),
  ];

  late final TextEditingController _organizationController;
  late final TextEditingController _workDaysController;
  late final TextEditingController _restDaysController;
  late DateTime _startDate;
  late Color _selectedColor;
  late bool _isEnabled;
  late List<ShiftAlarm> _alarms;
  late bool _showManualSchedule;
  String? _selectedPresetKey;

  @override
  void initState() {
    super.initState();
    final schedule = widget.schedule;
    _organizationController = TextEditingController(
      text: schedule?.organizationName ?? '',
    );
    _workDaysController = TextEditingController(
      text: '${schedule?.workDays ?? 5}',
    );
    _restDaysController = TextEditingController(
      text: '${schedule?.restDays ?? 2}',
    );
    _startDate = schedule?.startDate ?? _dateOnly(DateTime.now());
    _selectedColor = Color(schedule?.colorValue ?? _colors.first.toARGB32());
    _isEnabled = schedule?.isEnabled ?? true;
    _alarms = List.of(schedule?.alarms ?? const [ShiftAlarm(), ShiftAlarm()]);
    while (_alarms.length < 2) {
      _alarms.add(const ShiftAlarm());
    }
    _selectedPresetKey = _presetKeyFor(
      int.tryParse(_workDaysController.text) ?? 5,
      int.tryParse(_restDaysController.text) ?? 2,
    );
    _showManualSchedule = _selectedPresetKey == null;
  }

  @override
  void dispose() {
    _organizationController.dispose();
    _workDaysController.dispose();
    _restDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 720,
            maxHeight: MediaQuery.sizeOf(context).height * 0.94,
          ),
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.schedule == null
                              ? strings.addShiftSchedule
                              : strings.editShiftSchedule,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      IconButton(
                        tooltip: MaterialLocalizations.of(context)
                            .closeButtonTooltip,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _SectionLabel(strings.mainSettings),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 52,
                    child: TextFormField(
                      controller: _organizationController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: strings.organization,
                        filled: true,
                        fillColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _pickStartDate,
                      icon: const Icon(Icons.today_outlined, size: 20),
                      label: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${strings.startDate}: '
                          '${DateFormat.yMMMd(locale).format(_startDate)}',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionLabel(strings.scheduleSettings),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (var index = 0; index < _presets.length; index++) ...[
                        if (index > 0) const SizedBox(width: 8),
                        Expanded(
                          child: _PresetButton(
                            label: _presets[index].label(locale),
                            isSelected:
                                _selectedPresetKey == _presets[index].key,
                            onTap: () => _applyPreset(_presets[index]),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _showManualSchedule = !_showManualSchedule;
                      if (_showManualSchedule) _selectedPresetKey = null;
                    }),
                    icon: Icon(
                      _showManualSchedule
                          ? Icons.expand_less
                          : Icons.tune_outlined,
                    ),
                    label: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(strings.manualSchedule),
                    ),
                  ),
                  if (_showManualSchedule) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _workDaysController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: strings.workDays,
                              filled: true,
                              fillColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                            ),
                            onChanged: (_) => _syncPreset(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _restDaysController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: strings.restDays,
                              filled: true,
                              fillColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                            ),
                            onChanged: (_) => _syncPreset(),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  _SectionLabel(strings.scheduleColor),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const spacing = 8.0;
                      final width = (constraints.maxWidth - spacing * 3) / 4;
                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          for (final color in _colors)
                            SizedBox(
                              width: width,
                              child: _ColorSwatch(
                                color: color,
                                isSelected: color.toARGB32() ==
                                    _selectedColor.toARGB32(),
                                onTap: () =>
                                    setState(() => _selectedColor = color),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _SettingsSwitchRow(
                    icon: Icons.work_outline,
                    title: strings.enabled,
                    value: _isEnabled,
                    onChanged: (value) => setState(() => _isEnabled = value),
                  ),
                  const SizedBox(height: 12),
                  _SectionLabel(strings.reminders),
                  const SizedBox(height: 8),
                  for (var index = 0;
                      index < (_supportsNextDayAlarm ? 2 : 1);
                      index++) ...[
                    _AlarmEditorCard(
                      title: index == 1
                          ? strings.nextDayShiftAlarm
                          : strings.shiftAlarmNumber(1),
                      subtitle: index == 1
                          ? strings.nextDayShiftAlarmSubtitle
                          : strings.shiftAlarmSubtitle,
                      alarm: _alarms[index],
                      systemSoundLabel: strings.systemAlarmSound,
                      timeLabel: strings.time,
                      soundLabel: strings.chooseSound,
                      onToggle: (value) => _toggleAlarm(index, value),
                      onPickTime: () => _pickAlarmTime(index),
                      onPickSound: () => _pickAlarmSound(index),
                    ),
                    if (index == 0 && _supportsNextDayAlarm)
                      const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(strings.save),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) {
      return;
    }

    setState(() => _startDate = _dateOnly(picked));
  }

  void _applyPreset(_ShiftPreset preset) {
    setState(() {
      _selectedPresetKey = preset.key;
      _showManualSchedule = false;
      _workDaysController.text = '${preset.workDays}';
      _restDaysController.text = '${preset.restDays}';
      if (preset.key != '1/3') {
        _alarms[1] = _alarms[1].copyWith(isEnabled: false);
      }
    });
  }

  Future<void> _toggleAlarm(int index, bool enabled) async {
    if (enabled) {
      final allowed =
          await ref.read(notificationServiceProvider).requestPermissions();
      if (!allowed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Разрешите уведомления и точные будильники'),
          ),
        );
        return;
      }
    }
    if (mounted) {
      setState(() {
        _alarms[index] = _alarms[index].copyWith(isEnabled: enabled);
      });
    }
  }

  Future<void> _pickAlarmTime(int index) async {
    final alarm = _alarms[index];
    final picked = await showTimePicker(
      context: context,
      initialEntryMode: TimePickerEntryMode.inputOnly,
      initialTime: TimeOfDay(
        hour: alarm.timeMinutes ~/ 60,
        minute: alarm.timeMinutes % 60,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _alarms[index] = alarm.copyWith(
          timeMinutes: picked.hour * 60 + picked.minute,
        );
      });
    }
  }

  Future<void> _pickAlarmSound(int index) async {
    final alarm = _alarms[index];
    ReminderSoundSelection? sound;
    try {
      sound = await pickReminderSound(
        context,
        ref.read(notificationServiceProvider),
        currentUri: alarm.soundUri,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppStrings.of(context).soundPickerUnavailable)),
        );
      }
      return;
    }
    if (sound != null && mounted) {
      final selected = sound;
      setState(() {
        _alarms[index] = alarm.copyWith(
          soundUri: selected.uri,
          soundName: selected.name,
        );
      });
    }
  }

  void _syncPreset() {
    final workDays = int.tryParse(_workDaysController.text);
    final restDays = int.tryParse(_restDaysController.text);
    setState(() {
      _selectedPresetKey = workDays == null || restDays == null
          ? null
          : _presetKeyFor(
              workDays,
              restDays,
            );
      if (workDays != 1 || restDays != 3) {
        _alarms[1] = _alarms[1].copyWith(isEnabled: false);
      }
    });
  }

  Future<void> _save() async {
    final organizationName = _organizationController.text.trim();
    final workDays = int.tryParse(_workDaysController.text.trim());
    final restDays = int.tryParse(_restDaysController.text.trim());
    if (organizationName.isEmpty ||
        workDays == null ||
        workDays <= 0 ||
        restDays == null ||
        restDays < 0) {
      return;
    }

    final schedule = ShiftSchedule(
      id: widget.schedule?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      organizationName: organizationName,
      colorValue: _selectedColor.toARGB32(),
      startDate: _dateOnly(_startDate),
      workDays: workDays,
      restDays: restDays,
      isEnabled: _isEnabled,
      alarms: List.unmodifiable([
        _alarms.first,
        _supportsNextDayAlarm
            ? _alarms[1]
            : _alarms[1].copyWith(isEnabled: false),
      ]),
    );

    final controller = ref.read(shiftSchedulesControllerProvider.notifier);
    if (widget.schedule == null) {
      await controller.add(schedule);
    } else {
      await controller.update(schedule);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String? _presetKeyFor(int workDays, int restDays) {
    for (final preset in _presets) {
      if (preset.workDays == workDays && preset.restDays == restDays) {
        return preset.key;
      }
    }
    return null;
  }

  bool get _supportsNextDayAlarm {
    return int.tryParse(_workDaysController.text) == 1 &&
        int.tryParse(_restDaysController.text) == 3;
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}

String _formatMinutes(int minutes) {
  final hour = (minutes ~/ 60).toString().padLeft(2, '0');
  final minute = (minutes % 60).toString().padLeft(2, '0');
  return '$hour:$minute';
}
