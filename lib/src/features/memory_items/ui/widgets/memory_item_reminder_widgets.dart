part of '../memory_item_detail_screen.dart';

class _TimeReminderDraft {
  const _TimeReminderDraft({
    required this.timeMinutes,
    required this.reminderEnabled,
    required this.soundUri,
    required this.soundName,
  });

  final int? timeMinutes;
  final bool reminderEnabled;
  final String? soundUri;
  final String? soundName;
}

class _TimeReminderSheet extends StatefulWidget {
  const _TimeReminderSheet({
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
  State<_TimeReminderSheet> createState() => _TimeReminderSheetState();
}

class _TimeReminderSheetState extends State<_TimeReminderSheet> {
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
    final strings = AppStrings.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, 0, 18, 18 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.timeAndReminder,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 14),
            _ReminderSheetTile(
              icon: Icons.schedule_outlined,
              accentColor: const Color(0xFF218CFF),
              title: strings.time,
              value: _formattedTime(strings),
              onTap: _pickTime,
              trailing: _timeMinutes == null
                  ? null
                  : IconButton(
                      tooltip: strings.delete,
                      onPressed: () => setState(() {
                        _timeMinutes = null;
                        _reminderEnabled = false;
                        _error = null;
                      }),
                      icon: const Icon(Icons.close, size: 18),
                    ),
            ),
            const SizedBox(height: 5),
            _ReminderToggleTile(
              accentColor: Theme.of(context).colorScheme.primary,
              title: strings.soundNotification,
              subtitle: !widget.scheduler.isSupported
                  ? strings.androidOnlyReminder
                  : null,
              value: _reminderEnabled,
              onChanged: !widget.scheduler.isSupported || _busy
                  ? null
                  : _toggleReminder,
            ),
            if (_reminderEnabled) ...[
              const SizedBox(height: 5),
              _ReminderSheetTile(
                icon: Icons.music_note_outlined,
                accentColor: const Color(0xFF7C3AED),
                title: strings.chooseSound,
                value: _soundName ?? strings.systemAlarmSound,
                onTap: _busy ? null : _selectSound,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _soundUri == null || _busy
                      ? null
                      : () => setState(() {
                            _soundUri = null;
                            _soundName = null;
                          }),
                  child: Text(strings.useSystemSound),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                key: const ValueKey('memory_reminder_error'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
            const SizedBox(height: 10),
            NotebookActionButton(
              key: const ValueKey('memory_reminder_done'),
              onPressed: _busy ? null : _finish,
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              child: Text(strings.ready),
            ),
          ],
        ),
      ),
    );
  }

  String _formattedTime(AppStrings strings) {
    final minutes = _timeMinutes;
    if (minutes == null) {
      return strings.timeNotSet;
    }
    return formatMemoryTime(minutes);
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
    final minutes = _timeMinutes;
    if (_reminderEnabled &&
        (minutes == null ||
            !_reminderDateTime(minutes).isAfter(DateTime.now()))) {
      setState(() {
        _error = AppStrings.of(context).reminderFutureRequired;
      });
      return;
    }
    Navigator.of(context).pop(
      _TimeReminderDraft(
        timeMinutes: minutes,
        reminderEnabled: _reminderEnabled,
        soundUri: _soundUri,
        soundName: _soundName,
      ),
    );
  }

  DateTime _reminderDateTime(int minutes) => DateTime(
        widget.memoryDate.year,
        widget.memoryDate.month,
        widget.memoryDate.day,
        minutes ~/ 60,
        minutes % 60,
      );
}

class _ReminderSheetTile extends StatelessWidget {
  const _ReminderSheetTile({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.value,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tile = Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            SizedBox(
              width: 5,
              height: double.infinity,
              child: ColoredBox(color: accentColor),
            ),
            const SizedBox(width: 10),
            Icon(icon, color: accentColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.labelLarge),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            trailing ?? const Icon(Icons.chevron_right),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
    return NotebookPressable(onTap: onTap, child: tile);
  }
}

class _ReminderToggleTile extends StatelessWidget {
  const _ReminderToggleTile({
    required this.accentColor,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final Color accentColor;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final tile = Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            SizedBox(
              width: 5,
              height: double.infinity,
              child: ColoredBox(color: accentColor),
            ),
            const SizedBox(width: 10),
            Icon(Icons.notifications_active_outlined,
                color: accentColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.labelLarge),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                ],
              ),
            ),
            IgnorePointer(
              child: Switch.adaptive(value: value, onChanged: (_) {}),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
    return NotebookPressable(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: tile,
    );
  }
}
