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
      birthYear: _type == MemoryType.birthday ? _birthYear : null,
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
      _update(() => _isSaving = false);
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
    final item = _readItem();
    if (item == null) {
      final created = MemoryItem(
        id: snapshot.savedAt.microsecondsSinceEpoch.toString(),
        type: snapshot.type,
        title: snapshot.title,
        body: snapshot.body,
        timeMinutes: snapshot.timeMinutes,
        remindAt: snapshot.remindAt,
        reminderSoundUri: snapshot.reminderSoundUri,
        reminderSoundName: snapshot.reminderSoundName,
        memoryDate: snapshot.memoryDate,
        createdAt: snapshot.savedAt,
        updatedAt: snapshot.savedAt,
        status: snapshot.status,
        audioPath: snapshot.audioPath,
        audioDurationSeconds: snapshot.audioDurationSeconds,
        imagePaths: snapshot.imagePaths,
        repeatRule: snapshot.repeatRule,
        amountMinor: snapshot.amountMinor,
        paymentCategory: snapshot.paymentCategory,
        birthYear: snapshot.birthYear,
      );
      await ref.read(memoryItemsControllerProvider.notifier).add(created);
      if (_recurrenceFrequency != null) {
        await ref
            .read(recurrenceSeriesControllerProvider.notifier)
            .setFrequency(created, _recurrenceFrequency!);
      }
      _loadedItemId = created.id;

      if (mounted && widget.itemId == null) {
        context.replace('/memory/item/${Uri.encodeComponent(created.id)}');
      }
      return;
    }

    final updated = item.copyWith(
      type: snapshot.type,
      title: snapshot.title,
      body: snapshot.body,
      timeMinutes: snapshot.timeMinutes,
      clearTime: snapshot.timeMinutes == null,
      remindAt: snapshot.remindAt,
      clearReminder: snapshot.remindAt == null,
      reminderSoundUri: snapshot.reminderSoundUri,
      reminderSoundName: snapshot.reminderSoundName,
      memoryDate: snapshot.memoryDate,
      status: snapshot.status,
      audioPath: snapshot.audioPath,
      audioDurationSeconds: snapshot.audioDurationSeconds,
      clearAudio: snapshot.audioPath == null,
      imagePaths: snapshot.imagePaths,
      repeatRule: snapshot.repeatRule,
      clearRepeatRule: snapshot.repeatRule == null,
      amountMinor: snapshot.amountMinor,
      clearAmount: snapshot.amountMinor == null,
      paymentCategory: snapshot.paymentCategory,
      clearPaymentCategory: snapshot.paymentCategory == null,
      birthYear: snapshot.birthYear,
      clearBirthYear: snapshot.birthYear == null,
      updatedAt: snapshot.savedAt,
    );
    final persisted = ref
        .read(memoryItemsControllerProvider)
        .any((entry) => entry.id == item.id);
    if (_recurrenceFrequency != null) {
      if (item.repeatRule != _recurrenceFrequency!.name ||
          item.seriesId == null) {
        if (persisted) {
          await ref
              .read(memoryItemsControllerProvider.notifier)
              .update(updated);
        }
        await ref
            .read(recurrenceSeriesControllerProvider.notifier)
            .setFrequency(updated, _recurrenceFrequency!);
      } else if (_editFutureOccurrences) {
        await ref
            .read(recurrenceSeriesControllerProvider.notifier)
            .applyToFuture(
              updated,
              occurrenceDate: _originalOccurrenceDate,
            );
      } else if (!persisted || item.isGeneratedOccurrence) {
        await ref
            .read(recurrenceSeriesControllerProvider.notifier)
            .saveOccurrenceOverride(
              updated,
              occurrenceDate: _originalOccurrenceDate,
            );
      } else {
        await ref.read(memoryItemsControllerProvider.notifier).update(updated);
      }
    } else {
      await ref.read(memoryItemsControllerProvider.notifier).update(updated);
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
