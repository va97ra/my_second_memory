part of 'memory_item_detail_screen.dart';

extension _MemoryItemPersistence on _MemoryItemDetailScreenState {
  Future<void> _save({bool showMessage = true}) async {
    if (_formKey.currentState?.validate() == false) {
      return;
    }
    if (!_hasContent() && _readItem() == null) {
      return;
    }

    final now = DateTime.now();
    final snapshot = MemoryEditorDraft(
      type: _type,
      title: memoryTitleFromRecord(
        _bodyController.text,
        _type,
        Localizations.localeOf(context).languageCode,
      ),
      body: _bodyController.text.trim(),
      timeMinutes: _timeMinutes,
      remindAt: _remindAt,
      reminderSoundUri: _reminderSoundUri,
      reminderSoundName: _reminderSoundName,
      memoryDate: DateTime(
        _memoryDate.year,
        _memoryDate.month,
        _memoryDate.day,
      ),
      status: _status,
      audioPath: _audioPath,
      audioDurationSeconds: _audioDurationSeconds,
      imagePaths: List.unmodifiable(_imagePaths),
      savedAt: now,
      repeatRule: _recurrenceFrequency?.name,
      amountMinor: _parseAmountMinor(_amountController.text),
      paymentCategory:
          _type == MemoryType.payment ? _paymentCategory.name : null,
      subscriptionTermMonths: _type == MemoryType.payment &&
              _paymentCategory == PaymentCategory.subscription
          ? _subscriptionTermMonths
          : null,
      subscriptionTermDirty: _subscriptionTermDirty,
      birthYear: _type == MemoryType.birthday ? _birthYear : null,
      isUndated: _isUndated,
    );
    final revision = _saveCoordinator.beginSave();
    if (mounted) {
      _update(() {
        _isSaving = true;
        _saveError = null;
      });
    }

    final operation =
        _saveCoordinator.enqueue(() => _persistSnapshot(snapshot));

    try {
      await operation;
      if (!mounted || !_saveCoordinator.isCurrent(revision)) {
        return;
      }
      _update(() {
        _isSaving = false;
        final currentCategory =
            _type == MemoryType.payment ? _paymentCategory.name : null;
        final currentTerm = _type == MemoryType.payment &&
                _paymentCategory == PaymentCategory.subscription
            ? _subscriptionTermMonths
            : null;
        if (snapshot.subscriptionTermDirty &&
            snapshot.type == _type &&
            snapshot.repeatRule == _recurrenceFrequency?.name &&
            snapshot.paymentCategory == currentCategory &&
            snapshot.subscriptionTermMonths == currentTerm) {
          _subscriptionTermDirty = false;
        }
      });
      if (showMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.of(context).saved)),
        );
      }
    } catch (_) {
      if (!mounted || !_saveCoordinator.isCurrent(revision)) {
        return;
      }
      _update(() {
        _isSaving = false;
        _saveError = AppStrings.of(context).saveFailed;
      });
    }
  }

  Future<void> _persistSnapshot(MemoryEditorDraft snapshot) async {
    final outcome = await MemoryEditorSaver(
      items: ref.read(memoryItemsControllerProvider.notifier),
      series: ref.read(recurrenceSeriesControllerProvider.notifier),
    ).persist(
      snapshot,
      existing: _readItem(),
      refreshSeriesTemplate: _refreshNewSeriesTemplate,
      editFutureOccurrences: _editFutureOccurrences,
      originalOccurrenceDate: _originalOccurrenceDate,
    );

    if (!outcome.created) return;
    // Первое сохранение превращает черновик в запись: дальше редактор правит
    // её по идентификатору, а не заводит вторую.
    _loadedItemId = outcome.item.id;
    _refreshNewSeriesTemplate = true;
    _scopeRequested = true;
    if (mounted && widget.itemId == null) {
      context.replace(
        '/memory/item/${Uri.encodeComponent(outcome.item.id)}?new=1',
      );
    }
  }

  bool _hasContent() {
    return _bodyController.text.trim().isNotEmpty ||
        _imagePaths.isNotEmpty ||
        _audioPath != null ||
        (_type == MemoryType.payment &&
            _parseAmountMinor(_amountController.text) != null);
  }

  int? _parseAmountMinor(String raw) {
    final normalized = raw.trim().replaceAll(' ', '').replaceAll(',', '.');
    final value = double.tryParse(normalized);
    if (value == null || value < 0) return null;
    return (value * 100).round();
  }

  void _scheduleAutosave() {
    _saveCoordinator.schedule(
      canSave: !_isRecording && (_hasContent() || _readItem() != null),
      save: () async {
        if (mounted) await _save(showMessage: false);
      },
    );
  }

  Future<void> _flushAutosave() async {
    await _saveCoordinator.flush(
      canSave: !_isRecording && (_hasContent() || _readItem() != null),
      save: () => _save(showMessage: false),
    );
  }
}
