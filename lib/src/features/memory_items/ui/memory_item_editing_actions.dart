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

  Future<void> _pickSubscriptionTerm() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SubscriptionTermSheet(
        initialMonths: _subscriptionTermMonths,
      ),
    );
    if (selected == null || !mounted) return;
    _update(() {
      _subscriptionTermMonths = selected == 0 ? null : selected;
      _subscriptionTermDirty = true;
    });
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
                leading: const Icon(Icons.event_busy_rounded),
                title: Text(locale == 'ru' ? 'Не повторять' : 'Do not repeat'),
                trailing: _recurrenceFrequency == null
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.of(context).pop('none'),
              ),
              for (final frequency in RecurrenceFrequency.values)
                ListTile(
                  leading: Icon(frequency == RecurrenceFrequency.monthly
                      ? Icons.sync_rounded
                      : Icons.event_repeat_rounded),
                  title: Text(frequency.label(locale)),
                  trailing: _recurrenceFrequency == frequency
                      ? const Icon(Icons.check_rounded)
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
      _update(() {
        _recurrenceFrequency = null;
        if (_type == MemoryType.payment &&
            _paymentCategory == PaymentCategory.subscription) {
          _subscriptionTermMonths = null;
          _subscriptionTermDirty = true;
        }
      });
      if (item != null && item.seriesId != null) {
        await ref
            .read(recurrenceSeriesControllerProvider.notifier)
            .clearFrequency(item);
      }
    } else {
      _update(() {
        _recurrenceFrequency = RecurrenceFrequency.values.byName(selected);
        if (_recurrenceFrequency != RecurrenceFrequency.monthly &&
            _type == MemoryType.payment &&
            _paymentCategory == PaymentCategory.subscription) {
          _subscriptionTermMonths = null;
          _subscriptionTermDirty = true;
        }
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
              leading: const Icon(Icons.event_note_rounded),
              title: Text(locale == 'ru'
                  ? 'Редактировать только эту запись'
                  : 'Edit only this record'),
              onTap: () => Navigator.of(context).pop(false),
            ),
            ListTile(
              leading: const Icon(Icons.event_repeat_rounded),
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
      builder: (context) => MultiDatePickerSheet(sourceDate: item.memoryDate),
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
    final result = await showModalBottomSheet<TimeReminderDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => TimeReminderSheet(
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
    if (file == null) return;
    final stored = await _attachments.importImage(file);
    _update(() => _imagePaths.add(stored));
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
              leading: const Icon(Icons.photo_library_rounded),
              title: Text(strings.gallery),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
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
    if (!await _attachments.startVoice()) return;
    _update(() => _isRecording = true);
  }

  Future<void> _stopAndSaveVoice() async {
    final recording = await _attachments.stopVoice();
    _update(() {
      _isRecording = false;
      if (recording != null) {
        _audioPath = recording.path;
        _audioDurationSeconds = recording.durationSeconds;
      }
    });
    _scheduleAutosave();
  }
}
