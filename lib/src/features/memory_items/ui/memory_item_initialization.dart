part of 'memory_item_detail_screen.dart';

extension _MemoryItemInitialization on _MemoryItemDetailScreenState {
  void _initializeFrom(MemoryItem item) {
    if (_loadedItemId == item.id) {
      return;
    }
    _loadedItemId = item.id;
    _bodyController.text = item.body;
    _memoryDate = item.memoryDate;
    _originalOccurrenceDate = item.seriesId == null ? null : item.memoryDate;
    _timeMinutes = item.timeMinutes;
    _remindAt = item.remindAt;
    _reminderSoundUri = item.reminderSoundUri;
    _reminderSoundName = item.reminderSoundName;
    _status = item.status;
    _type =
        editableMemoryTypes.contains(item.type) ? item.type : MemoryType.note;
    _audioPath = item.audioPath;
    _audioDurationSeconds = item.audioDurationSeconds;
    _imagePaths
      ..clear()
      ..addAll(item.imagePaths);
    _recurrenceFrequency = switch (item.repeatRule) {
      'monthly' => RecurrenceFrequency.monthly,
      'yearly' => RecurrenceFrequency.yearly,
      _ => null,
    };
    _amountController.text = item.amountMinor == null
        ? ''
        : (item.amountMinor! / 100).toStringAsFixed(2).replaceFirst('.00', '');
    _paymentCategory = PaymentCategory.other;
    for (final category in PaymentCategory.values) {
      if (category.name == item.paymentCategory) {
        _paymentCategory = category;
        break;
      }
    }
    _birthYear = item.birthYear;
    if (item.seriesId != null && !_scopeRequested) {
      _scopeRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _askEditScope());
    }
  }

  void _initializeNew() {
    if (_loadedItemId == '__new__') {
      return;
    }
    final date = widget.initialDate ?? DateTime.now();
    _loadedItemId = '__new__';
    _bodyController.clear();
    _memoryDate = DateTime(date.year, date.month, date.day);
    _originalOccurrenceDate = null;
    _timeMinutes = null;
    _remindAt = null;
    _reminderSoundUri = null;
    _reminderSoundName = null;
    _status = MemoryStatus.active;
    _type = MemoryType.note;
    _audioPath = null;
    _audioDurationSeconds = null;
    _imagePaths.clear();
    _recurrenceFrequency = null;
    _amountController.clear();
    _paymentCategory = PaymentCategory.other;
    _birthYear = null;
  }

  void _changeType(MemoryType type) {
    _update(() {
      _type = type;
      if (type == MemoryType.birthday) {
        _recurrenceFrequency = RecurrenceFrequency.yearly;
        _timeMinutes ??= 9 * 60;
        _remindAt = _dateTimeFor(_memoryDate, _timeMinutes!)
            .subtract(const Duration(days: 1));
      } else if (type == MemoryType.payment) {
        _recurrenceFrequency = RecurrenceFrequency.monthly;
        _timeMinutes ??= 9 * 60;
        _remindAt = _dateTimeFor(_memoryDate, _timeMinutes!)
            .subtract(const Duration(days: 3));
      }
    });
  }

  Widget? _buildSpecialFields() {
    final locale = Localizations.localeOf(context).languageCode;
    if (_type == MemoryType.payment) {
      return _PaymentFields(
        amountController: _amountController,
        category: _paymentCategory,
        locale: locale,
        onCategoryChanged: (category) {
          _update(() => _paymentCategory = category);
          _scheduleAutosave();
        },
        onChanged: _scheduleAutosave,
      );
    }
    if (_type == MemoryType.birthday) {
      return _BirthdayFields(
        birthYear: _birthYear,
        locale: locale,
        onTap: _pickBirthYear,
        onClear: _birthYear == null
            ? null
            : () {
                _update(() => _birthYear = null);
                _scheduleAutosave();
              },
      );
    }
    return null;
  }
}
