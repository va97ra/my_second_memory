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
    _isUndated = item.isUndated;
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
    _subscriptionTermMonths = _readSubscriptionTermMonths(item);
    _subscriptionTermDirty = false;
    _birthYear = item.birthYear;
    if (item.seriesId != null && !_scopeRequested) {
      _scopeRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _askEditScope());
    }
  }

  void _initializeNew() {
    if (_loadedItemId == _MemoryItemDetailScreenState._newRecordKey) {
      return;
    }
    final date = widget.initialDate ?? DateTime.now();
    _loadedItemId = _MemoryItemDetailScreenState._newRecordKey;
    _bodyController.clear();
    _memoryDate = DateTime(date.year, date.month, date.day);
    _originalOccurrenceDate = null;
    _timeMinutes = null;
    _remindAt = null;
    _reminderSoundUri = null;
    _reminderSoundName = null;
    _status = MemoryStatus.active;
    _isUndated = widget.createUndated;
    _type = MemoryType.note;
    _audioPath = null;
    _audioDurationSeconds = null;
    _imagePaths.clear();
    _recurrenceFrequency = null;
    _amountController.clear();
    _paymentCategory = PaymentCategory.other;
    _subscriptionTermMonths = null;
    _subscriptionTermDirty = false;
    _birthYear = null;
  }

  void _changeType(MemoryType type) {
    final wasPayment = _type == MemoryType.payment;
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
      if (type != MemoryType.payment) {
        _subscriptionTermMonths = null;
      }
      if (wasPayment != (type == MemoryType.payment)) {
        _subscriptionTermDirty = true;
      }
    });
  }

  int? _readSubscriptionTermMonths(MemoryItem item) {
    if (item.type != MemoryType.payment ||
        _paymentCategory != PaymentCategory.subscription ||
        item.seriesId == null) {
      return null;
    }
    RecurrenceSeries? matching;
    for (final series in ref.read(recurrenceSeriesControllerProvider)) {
      if (series.id == item.seriesId) {
        matching = series;
        break;
      }
    }
    final endDate = matching?.subscriptionEndDate;
    if (matching == null || endDate == null) return null;
    final occurrenceDate = DateTime(
      item.memoryDate.year,
      item.memoryDate.month,
      item.memoryDate.day,
    );
    final seriesStart = DateTime(
      matching.startDate.year,
      matching.startDate.month,
      matching.startDate.day,
    );
    final termStart =
        occurrenceDate.isAfter(seriesStart) ? occurrenceDate : seriesStart;
    final months = (endDate.year - termStart.year) * 12 +
        endDate.month -
        termStart.month +
        1;
    return months < 1 ? 1 : months;
  }

  Widget? _buildSpecialFields() {
    final locale = Localizations.localeOf(context).languageCode;
    if (_type == MemoryType.payment) {
      final item = _readItem();
      final canEditSubscriptionTerm =
          _recurrenceFrequency == RecurrenceFrequency.monthly &&
              (item?.seriesId == null ||
                  _editFutureOccurrences ||
                  _refreshNewSeriesTemplate);
      return _PaymentFields(
        amountController: _amountController,
        category: _paymentCategory,
        locale: locale,
        onCategoryChanged: (category) {
          _update(() {
            if (_paymentCategory != category) {
              _subscriptionTermDirty = true;
            }
            _paymentCategory = category;
            if (category != PaymentCategory.subscription) {
              _subscriptionTermMonths = null;
            }
          });
          _scheduleAutosave();
        },
        onChanged: _scheduleAutosave,
        subscriptionTermMonths: _subscriptionTermMonths,
        onSubscriptionTermTap:
            canEditSubscriptionTerm ? _pickSubscriptionTerm : null,
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
