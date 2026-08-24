import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';
import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import '../../../../shared/ui/reminder_sound_picker.dart';
import 'time_reminder_draft.dart';
import 'time_reminder_sheet_body.dart';

/// Лист выбора времени записи и напоминания о ней.
class TimeReminderSheet extends StatefulWidget {
  const TimeReminderSheet({
    super.key,
    required this.initialTimeMinutes,
    required this.initialReminderEnabled,
    required this.initialSoundUri,
    required this.initialSoundName,
    required this.memoryDate,
    required this.scheduler,
  });

  final int? initialTimeMinutes;
  final bool initialReminderEnabled;
  final String? initialSoundUri;
  final String? initialSoundName;
  final DateTime memoryDate;
  final ReminderScheduler scheduler;

  @override
  State<TimeReminderSheet> createState() => _TimeReminderSheetState();
}

class _TimeReminderSheetState extends State<TimeReminderSheet> {
  int? _timeMinutes;
  late bool _reminderEnabled;
  String? _soundUri;
  String? _soundName;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _timeMinutes = widget.initialTimeMinutes;
    _reminderEnabled = widget.initialReminderEnabled;
    _soundUri = widget.initialSoundUri;
    _soundName = widget.initialSoundName;
  }

  @override
  Widget build(BuildContext context) {
    return TimeReminderSheetBody(
      timeText: _formattedTime(AppStrings.of(context)),
      reminderEnabled: _reminderEnabled,
      reminderSupported: widget.scheduler.isSupported,
      soundName: _soundName,
      hasOwnSound: _soundUri != null,
      busy: _busy,
      error: _error,
      onPickTime: _pickTime,
      onClearTime: _timeMinutes == null
          ? null
          : () => setState(() {
                _timeMinutes = null;
                _reminderEnabled = false;
                _error = null;
              }),
      onToggleReminder: _toggleReminder,
      onSelectSound: _selectSound,
      onUseSystemSound: () => setState(() {
        _soundUri = null;
        _soundName = null;
      }),
      onDone: _finish,
    );
  }

  String _formattedTime(AppStrings strings) {
    final minutes = _timeMinutes;
    if (minutes == null) {
      return strings.timeNotSet;
    }
    return formatMinutesOfDay(minutes);
  }

  Future<bool> _pickTime() async {
    final minutes = _timeMinutes;
    final picked = await showTimePicker(
      context: context,
      initialEntryMode: TimePickerEntryMode.inputOnly,
      initialTime: minutes == null
          ? TimeOfDay.now()
          : TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    if (picked == null || !mounted) {
      return false;
    }
    setState(() {
      _timeMinutes = picked.hour * 60 + picked.minute;
      _error = null;
    });
    return true;
  }

  Future<void> _toggleReminder(bool enabled) async {
    if (!enabled) {
      setState(() {
        _reminderEnabled = false;
        _error = null;
      });
      return;
    }
    if (_timeMinutes == null && !await _pickTime()) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final allowed = await widget.scheduler.requestPermissions();
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      _reminderEnabled = allowed;
      if (!allowed) {
        _error = AppStrings.of(context).reminderPermissionRequired;
      }
    });
  }

  Future<void> _selectSound() async {
    setState(() => _busy = true);
    ReminderSoundSelection? selected;
    try {
      selected = await pickReminderSound(
        context,
        widget.scheduler,
        currentUri: _soundUri,
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = AppStrings.of(context).soundPickerUnavailable;
        });
      }
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      if (selected != null) {
        _soundUri = selected.uri;
        _soundName = selected.name;
      }
    });
  }

  void _finish() {
    if (_reminderEnabled && !canRemindAt(widget.memoryDate, _timeMinutes)) {
      setState(() => _error = AppStrings.of(context).reminderFutureRequired);
      return;
    }
    Navigator.of(context).pop(
      TimeReminderDraft(
        timeMinutes: _timeMinutes,
        reminderEnabled: _reminderEnabled,
        soundUri: _soundUri,
        soundName: _soundName,
      ),
    );
  }
}
