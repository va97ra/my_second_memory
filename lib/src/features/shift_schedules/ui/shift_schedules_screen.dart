import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
import '../../../shared/ui/empty_state.dart';
import '../../../shared/ui/screen_chrome.dart';
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: const AppBackButton(fallbackLocation: '/settings'),
        title: Text(
          strings.shiftSchedules,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF172033),
                fontWeight: FontWeight.w900,
              ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFDDE7F3)),
        ),
      ),
      body: ColoredBox(
        color: const Color(0x12A66F3F),
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
                    : const Color(0xFFDDE7F3),
              ),
              color: schedule.isEnabled
                  ? color.withValues(alpha: 0.1)
                  : const Color(0xFFFFFCF7).withValues(alpha: 0.92),
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
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: const Color(0xFF172033),
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${schedule.workDays}/${schedule.restDays} · $dateText',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
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
    Color(0xFF2563EB),
    Color(0xFF0891B2),
    Color(0xFF16A34A),
    Color(0xFFF59E0B),
    Color(0xFFEA580C),
    Color(0xFFDB2777),
    Color(0xFF7C3AED),
    Color(0xFF475569),
  ];

  static const _presets = [
    _ShiftPreset('5/2', '5/2', '5/2', 5, 2),
    _ShiftPreset('2/2', '2/2', '2/2', 2, 2),
    _ShiftPreset('1/3', 'сутки/трое', '24h/3 off', 1, 3),
    _ShiftPreset('7/7', '7/7', '7/7', 7, 7),
    _ShiftPreset('14/14', '14/14', '14/14', 14, 14),
    _ShiftPreset('15/15', '15/15', '15/15', 15, 15),
    _ShiftPreset('30/30', '30/30', '30/30', 30, 30),
  ];

  late final TextEditingController _organizationController;
  late final TextEditingController _workDaysController;
  late final TextEditingController _restDaysController;
  late DateTime _startDate;
  late Color _selectedColor;
  late bool _isEnabled;
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
    _selectedPresetKey = _presetKeyFor(
      int.tryParse(_workDaysController.text) ?? 5,
      int.tryParse(_restDaysController.text) ?? 2,
    );
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
          constraints: const BoxConstraints(maxWidth: 720),
          child: Material(
            color: const Color(0xFFFFFCF7),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              side: BorderSide(color: Color(0xFFDDE7F3)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.schedule == null
                              ? strings.addShiftSchedule
                              : strings.editShiftSchedule,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: const Color(0xFF172033),
                                    fontWeight: FontWeight.w900,
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
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _organizationController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: strings.organization,
                      filled: true,
                      fillColor: const Color(0xFFFFF8EE),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _pickStartDate,
                    icon: const Icon(Icons.today_outlined),
                    label: Text(
                      '${strings.startDate}: '
                      '${DateFormat.yMMMd(locale).format(_startDate)}',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    strings.schedulePreset,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final preset in _presets)
                        ChoiceChip(
                          label: Text(preset.label(locale)),
                          selected: _selectedPresetKey == preset.key,
                          onSelected: (_) => _applyPreset(preset),
                        ),
                      ChoiceChip(
                        label: Text(strings.customSchedule),
                        selected: _selectedPresetKey == null,
                        onSelected: (_) => setState(() {
                          _selectedPresetKey = null;
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _workDaysController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: strings.workDays,
                            filled: true,
                            fillColor: const Color(0xFFFFF8EE),
                          ),
                          onChanged: (_) => _syncPreset(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _restDaysController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: strings.restDays,
                            filled: true,
                            fillColor: const Color(0xFFFFF8EE),
                          ),
                          onChanged: (_) => _syncPreset(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final color in _colors)
                        _ColorSwatch(
                          color: color,
                          isSelected:
                              color.toARGB32() == _selectedColor.toARGB32(),
                          onTap: () => setState(() {
                            _selectedColor = color;
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(strings.enabled),
                    value: _isEnabled,
                    onChanged: (value) => setState(() {
                      _isEnabled = value;
                    }),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(strings.save),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
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
      _workDaysController.text = '${preset.workDays}';
      _restDaysController.text = '${preset.restDays}';
    });
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

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
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
        width: 38,
        height: 38,
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
