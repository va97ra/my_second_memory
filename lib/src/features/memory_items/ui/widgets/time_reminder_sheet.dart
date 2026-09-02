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
    required this.initialLeadMinutes,
    required this.initialSoundUri,
    required this.initialSoundName,
    required this.memoryDate,
    required this.scheduler,
  });

  final int? initialTimeMinutes;
  final bool initialReminderEnabled;
  final int initialLeadMinutes;
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
  late int _leadMinutes;
  String? _soundUri;
  String? _soundName;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _timeMinutes = widget.initialTimeMinutes;
    _reminderEnabled = widget.initialReminderEnabled;
    _leadMinutes = widget.initialLeadMinutes;
    _soundUri = widget.initialSoundUri;
    _soundName = widget.initialSoundName;
  }

  @override
  Widget build(BuildContext context) {
    return TimeReminderSheetBody(
      timeMinutes: _timeMinutes,
      reminderEnabled: _reminderEnabled,
      leadMinutes: _leadMinutes,
      onLeadChanged: (lead) => setState(() => _leadMinutes = lead),
      reminderSupported: widget.scheduler.isSupported,
      soundName: _soundName,
      hasOwnSound: _soundUri != null,
      busy: _busy,
      error: _error,
      onTimeChanged: _setTime,
      onClearTime: _timeMinutes == null ? null : _clearTime,
      onToggleReminder: _toggleReminder,
      onSelectSound: _selectSound,
      onUseSystemSound: _useSystemSound,
      onDone: _finish,
    );
  }

  /// Убранное время уносит с собой и напоминание: напоминать не о чем.
  void _clearTime() {
    setState(() {
      _timeMinutes = null;
      _reminderEnabled = false;
      _error = null;
    });
  }

  void _useSystemSound() {
    setState(() {
      _soundUri = null;
      _soundName = null;
    });
  }

  void _setTime(int minutes) {
    setState(() {
      _timeMinutes = minutes;
      _error = null;
    });
  }

  Future<void> _toggleReminder(bool enabled) async {
    if (!enabled) {
      setState(() {
        _reminderEnabled = false;
        _error = null;
      });
      return;
    }
    // Напоминать не о чем, пока время не введено: поля времени теперь прямо
    // в листе, и человеку показывают, чего не хватает, а не открывают диалог.
    if (_timeMinutes == null) {
      setState(() => _error = AppStrings.of(context).timeNotSet);
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
      // Без разрешения напоминание не сработает, поэтому переключатель не
      // остаётся включённым: он не должен обещать несбыточного.
      _error =
          allowed ? null : AppStrings.of(context).reminderPermissionRequired;
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
        leadMinutes: _leadMinutes,
        soundUri: _soundUri,
        soundName: _soundName,
      ),
    );
  }
}
