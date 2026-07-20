import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
import '../../../shared/ui/empty_state.dart';
import '../../../shared/ui/screen_chrome.dart';
import '../../notifications/data/notification_service.dart';
import '../../notifications/ui/reminder_sound_picker.dart';
import '../domain/shift_schedule.dart';
import '../state/shift_schedules_controller.dart';

class ShiftSchedulesScreen extends ConsumerWidget {
  const ShiftSchedulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final schedules = ref.watch(shiftSchedulesControllerProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: const AppBackButton(fallbackLocation: '/settings'),
        title: Text(
          strings.shiftSchedules,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w900,
              ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      body: WarmGradientBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Align(
                alignment: Alignment.topCenter,
                child: Column(
                  children: [
                    if (schedules.isEmpty)
                      AppEmptyState(
                        icon: Icons.work_history_outlined,
                        title: strings.noShiftSchedules,
                        actionLabel: strings.addShiftSchedule,
                        onAction: () => _openEditor(context, ref),
                      )
                    else
                      for (final schedule in schedules)
                        _ShiftScheduleTile(
                          schedule: schedule,
                          locale: locale,
                          onEdit: () => _openEditor(context, ref, schedule),
                          onToggle: () {
                            ref
                                .read(shiftSchedulesControllerProvider.notifier)
                                .toggleEnabled(schedule.id);
                          },
                          onDelete: () =>
                              _confirmDelete(context, ref, schedule.id),
                        ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref),
        icon: const Icon(Icons.add),
        label: Text(strings.addShiftSchedule),
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, [
    ShiftSchedule? schedule,
  ]) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ShiftScheduleEditorSheet(schedule: schedule);
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.deleteShiftScheduleQuestion),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(strings.delete),
            ),
          ],
        );
      },
    );

    if (confirmed ?? false) {
      await ref.read(shiftSchedulesControllerProvider.notifier).delete(id);
    }
  }
}

class _ShiftScheduleTile extends StatelessWidget {
  const _ShiftScheduleTile({
    required this.schedule,
    required this.locale,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final ShiftSchedule schedule;
  final String locale;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = Color(schedule.colorValue);
    final dateText = DateFormat.yMMMd(locale).format(schedule.startDate);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onEdit,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: schedule.isEnabled
                    ? color.withValues(alpha: 0.34)
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
              color: schedule.isEnabled
                  ? color.withValues(alpha: 0.1)
                  : Theme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: 0.92),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: schedule.isEnabled ? 0.1 : 0),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const SizedBox(width: 38, height: 38),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schedule.organizationName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${schedule.workDays}/${schedule.restDays} · $dateText',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        if (schedule.alarms.asMap().entries.any((entry) =>
                            entry.value.isEnabled &&
                            (entry.key == 0 ||
                                schedule.supportsNextDayAlarm))) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.alarm_outlined,
                                size: 15,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  schedule.alarms
                                      .asMap()
                                      .entries
                                      .where((entry) =>
                                          entry.value.isEnabled &&
                                          (entry.key == 0 ||
                                              schedule.supportsNextDayAlarm))
                                      .map((entry) => entry.key == 1
                                          ? '+1 д. ${_formatMinutes(entry.value.timeMinutes)}'
                                          : _formatMinutes(
                                              entry.value.timeMinutes))
                                      .join(' · '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Switch(
                    value: schedule.isEnabled,
                    onChanged: (_) => onToggle(),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      }
                      if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(AppStrings.of(context).editShiftSchedule),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(AppStrings.of(context).delete),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
                Icons.check,
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
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  Icon(
                    Icons.alarm_outlined,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
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
                                    fontWeight: FontWeight.w400,
                                  ),
                        ),
                      ],
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
              icon: Icons.schedule_outlined,
              title: timeLabel,
              value: _formatMinutes(alarm.timeMinutes),
              onTap: onPickTime,
            ),
            const Divider(height: 1, indent: 44, endIndent: 12),
            _AlarmActionRow(
              icon: Icons.music_note_outlined,
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
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: double.infinity,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.white,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withValues(alpha: 0.28),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
          ],
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : null,
      ),
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
