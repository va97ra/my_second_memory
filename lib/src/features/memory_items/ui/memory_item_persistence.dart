part of 'memory_item_detail_screen.dart';

extension _MemoryItemPersistence on _MemoryItemDetailScreenState {
  Future<void> _save({bool showMessage = true}) async {
    if (_formKey.currentState?.validate() == false) {
      return;
    }
    if (!_hasContent() && _readItem() == null) {
      return;
    }

    final snapshot = _form.toDraft(
      title: memoryTitleFromRecord(
        _bodyController.text,
        _form.type,
        Localizations.localeOf(context).languageCode,
      ),
      body: _bodyController.text.trim(),
      amountMinor: _parseAmountMinor(_amountController.text),
      savedAt: DateTime.now(),
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
        // Отметку «срок трогали» снимаем только если с начала сохранения
        // ничего из того, что попало в серию, не изменилось снова.
        if (_savedTermMatchesForm(snapshot)) {
          _form = _form.copyWith(subscriptionTermDirty: false);
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

  bool _savedTermMatchesForm(MemoryEditorDraft snapshot) {
    if (!snapshot.subscriptionTermDirty) return false;
    final current = _form.toDraft(
      title: snapshot.title,
      body: snapshot.body,
      amountMinor: snapshot.amountMinor,
      savedAt: snapshot.savedAt,
    );
    return snapshot.type == current.type &&
        snapshot.repeatRule == current.repeatRule &&
        snapshot.paymentCategory == current.paymentCategory &&
        snapshot.subscriptionTermMonths == current.subscriptionTermMonths;
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
      originalOccurrenceDate: _form.originalOccurrenceDate,
    );

    if (!outcome.created) return;
    // Первое сохранение превращает черновик в запись: дальше редактор правит
    // её по идентификатору, а не заводит вторую.
    _loadedItemId = outcome.item.id;
    _refreshNewSeriesTemplate = true;
    _scopeRequested = true;
    if (mounted && widget.itemId == null) {
      // Записку заводят с панели, поэтому новый адрес несёт её пункт: иначе
      // панель исчезнет в тот момент, когда автосохранение сменит адрес.
      final panel = widget.createUndated ? '&panel=add_note' : '';
      context.replace(
        '/memory/item/${Uri.encodeComponent(outcome.item.id)}?new=1$panel',
      );
    }
  }

  bool _hasContent() {
    return _bodyController.text.trim().isNotEmpty ||
        _form.hasAttachments ||
        (_form.type == MemoryType.payment &&
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
