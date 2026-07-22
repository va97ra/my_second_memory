part of 'memory_item_detail_screen.dart';

extension _MemoryItemEditingActions on _MemoryItemDetailScreenState {
  Future<void> _pickBirthYear() async {
    final controller = TextEditingController(
      text: _birthYear?.toString() ?? '',
    );
    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          Localizations.localeOf(context).languageCode == 'ru'
              ? 'Год рождения'
              : 'Birth year',
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: const InputDecoration(hintText: '1985'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppStrings.of(context).cancel),
          ),
          FilledButton(
            onPressed: () {
              final year = int.tryParse(controller.text);
              Navigator.of(context).pop(
                year != null && year >= 1900 && year <= DateTime.now().year
                    ? year
                    : null,
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || !mounted) return;
    _update(() => _birthYear = value);
    _scheduleAutosave();
  }

  Future<void> _openRepeatPicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final locale = Localizations.localeOf(context).languageCode;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.event_busy_outlined),
                title: Text(locale == 'ru' ? 'Не повторять' : 'Do not repeat'),
                trailing: _recurrenceFrequency == null
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.of(context).pop('none'),
              ),
              for (final frequency in RecurrenceFrequency.values)
                ListTile(
                  leading: Icon(frequency == RecurrenceFrequency.monthly
                      ? Icons.sync_outlined
                      : Icons.event_repeat),
                  title: Text(frequency.label(locale)),
                  trailing: _recurrenceFrequency == frequency
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => Navigator.of(context).pop(frequency.name),
                ),
            ],
          ),
        );
      },
    );
    if (selected == null || !mounted) return;
    final item = _readItem();
    if (selected == 'none') {
      _update(() => _recurrenceFrequency = null);
      if (item != null && item.seriesId != null) {
        await ref
            .read(recurrenceSeriesControllerProvider.notifier)
            .clearFrequency(item);
      }
    } else {
      _update(() {
        _recurrenceFrequency = RecurrenceFrequency.values.byName(selected);
      });
    }
    _scheduleAutosave();
  }

  Future<void> _askEditScope() async {
    if (!mounted) return;
    final locale = Localizations.localeOf(context).languageCode;
    final applyFuture = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.event_note_outlined),
              title: Text(locale == 'ru'
                  ? 'Редактировать только эту запись'
                  : 'Edit only this record'),
              onTap: () => Navigator.of(context).pop(false),
            ),
            ListTile(
              leading: const Icon(Icons.event_repeat),
              title: Text(locale == 'ru'
                  ? 'Эту и будущие записи'
                  : 'This and future records'),
              onTap: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
    if (mounted && applyFuture != null) {
      _update(() => _editFutureOccurrences = applyFuture);
    }
  }

  Future<void> _duplicateToDates(MemoryItem item) async {
    await _flushAutosave();
    if (!mounted) return;
    final dates = await showModalBottomSheet<List<DateTime>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _MultiDatePickerSheet(sourceDate: item.memoryDate),
    );
    if (dates == null || dates.isEmpty || !mounted) return;
    final copies = await ref
        .read(memoryItemsControllerProvider.notifier)
        .duplicateToDates(item, dates);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Localizations.localeOf(context).languageCode == 'ru'
                ? 'Создано копий: ${copies.length}'
                : 'Copies created: ${copies.length}',
          ),
        ),
      );
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _memoryDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) {
      return;
    }
    _update(() {
      _memoryDate = DateTime(date.year, date.month, date.day);
      if (_remindAt != null && _timeMinutes != null) {
        final nextReminder = _dateTimeFor(_memoryDate, _timeMinutes!);
        _remindAt = nextReminder.isAfter(DateTime.now()) ? nextReminder : null;
      }
    });
    _scheduleAutosave();
  }

  String _formattedDate(BuildContext context) {
    return DateFormat('d MMM y', Localizations.localeOf(context).languageCode)
        .format(_memoryDate);
  }

  String? _formattedTime() {
    final minutes = _timeMinutes;
    if (minutes == null) {
      return null;
    }
    return formatMemoryTime(minutes);
  }

  Future<void> _openTimeAndReminder() async {
    final result = await showModalBottomSheet<_TimeReminderDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => _TimeReminderSheet(
        initialTimeMinutes: _timeMinutes,
        initialReminderEnabled: _remindAt != null,
        initialSoundUri: _reminderSoundUri,
        initialSoundName: _reminderSoundName,
        memoryDate: _memoryDate,
        scheduler: ref.read(notificationServiceProvider),
      ),
    );
    if (result == null || !mounted) {
      return;
    }
    _update(() {
      _timeMinutes = result.timeMinutes;
      _remindAt = result.reminderEnabled && result.timeMinutes != null
          ? _dateTimeFor(_memoryDate, result.timeMinutes!)
          : null;
      _reminderSoundUri = result.soundUri;
      _reminderSoundName = result.soundName;
    });
    _scheduleAutosave();
  }

  DateTime _dateTimeFor(DateTime date, int minutes) => DateTime(
        date.year,
        date.month,
        date.day,
        minutes ~/ 60,
        minutes % 60,
      );

  Future<void> _pickImage() async {
    final file = kIsWeb ? await _pickImageForWeb() : await _pickImageForIo();
    if (file == null) {
      return;
    }

    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      final mimeType = file.mimeType ?? _mimeTypeForName(file.name);
      final dataUrl = 'data:$mimeType;base64,${base64Encode(bytes)}';
      _update(() => _imagePaths.add(dataUrl));
      _scheduleAutosave();
      return;
    }

    final savedPath = await _mediaStorage.saveImage(file);
    _update(() => _imagePaths.add(savedPath));
    _scheduleAutosave();
  }

  Future<XFile?> _pickImageForWeb() async {
    const imageGroup = file_selector.XTypeGroup(
      label: 'Images',
      extensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
    );
    return file_selector.openFile(acceptedTypeGroups: [imageGroup]);
  }

  Future<XFile?> _pickImageForIo() async {
    final strings = AppStrings.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(strings.gallery),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(strings.camera),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) {
      return null;
    }
    return _imagePicker.pickImage(source: source, imageQuality: 92);
  }

  Future<void> _startVoice() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      return;
    }

    final path = await _mediaStorage.createVoicePath();
    await _recorder.start(const RecordConfig(), path: path);
    _update(() {
      _recordingStartedAt = DateTime.now();
      _isRecording = true;
    });
  }

  Future<void> _stopAndSaveVoice() async {
    final path = await _recorder.stop();
    final startedAt = _recordingStartedAt;
    final duration =
        startedAt == null ? 0 : DateTime.now().difference(startedAt).inSeconds;

    _update(() {
      _recordingStartedAt = null;
      _isRecording = false;
      if (path != null) {
        _audioPath = path;
        _audioDurationSeconds = duration;
      }
    });
    _scheduleAutosave();
  }

  String _mimeTypeForName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.gif')) {
      return 'image/gif';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }
}
