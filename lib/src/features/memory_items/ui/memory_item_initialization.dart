part of 'memory_item_detail_screen.dart';

extension _MemoryItemInitialization on _MemoryItemDetailScreenState {
  void _initializeFrom(MemoryItem item) {
    if (_loadedItemId == item.id) {
      return;
    }
    _loadedItemId = item.id;
    _bodyController.text = item.body;
    _amountController.text = _formatAmount(item.amountMinor);
    _form = MemoryEditorForm.fromItem(
      item,
      subscriptionTermMonths: _readSubscriptionTermMonths(item),
    );
    if (item.seriesId != null && !_scopeRequested) {
      _scopeRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _askEditScope());
    }
  }

  void _initializeNew() {
    if (_loadedItemId == _MemoryItemDetailScreenState._newRecordKey) {
      return;
    }
    _loadedItemId = _MemoryItemDetailScreenState._newRecordKey;
    _bodyController.clear();
    _amountController.clear();
    _form = MemoryEditorForm.blank(
      date: widget.initialDate ?? DateTime.now(),
      isUndated: widget.createUndated,
    );
  }

  void _changeType(MemoryType type) {
    _update(() => _form = _form.withType(type));
  }

  String _formatAmount(int? amountMinor) {
    if (amountMinor == null) return '';
    return (amountMinor / 100).toStringAsFixed(2).replaceFirst('.00', '');
  }

  /// Сколько месяцев осталось в сроке подписки, считая от вхождения, которое
  /// открыли. Срок принадлежит серии, поэтому читается из неё, а не из записи.
  int? _readSubscriptionTermMonths(MemoryItem item) {
    if (item.type != MemoryType.payment ||
        item.paymentCategory != PaymentCategory.subscription.name ||
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
    if (_form.type == MemoryType.payment) {
      final item = _readItem();
      final canEditSubscriptionTerm =
          _form.recurrenceFrequency == RecurrenceFrequency.monthly &&
              (item?.seriesId == null ||
                  _editFutureOccurrences ||
                  _refreshNewSeriesTemplate);
      return PaymentFields(
        amountController: _amountController,
        category: _form.paymentCategory,
        locale: locale,
        onCategoryChanged: (category) {
          _update(() => _form = _form.withPaymentCategory(category));
          _scheduleAutosave();
        },
        onChanged: _scheduleAutosave,
        subscriptionTermMonths: _form.subscriptionTermMonths,
        onSubscriptionTermTap:
            canEditSubscriptionTerm ? _pickSubscriptionTerm : null,
      );
    }
    if (_form.type == MemoryType.birthday) {
      return BirthdayFields(
        birthYear: _form.birthYear,
        locale: locale,
        onTap: _pickBirthYear,
        onClear: _form.birthYear == null
            ? null
            : () {
                _update(() => _form = _form.copyWith(clearBirthYear: true));
                _scheduleAutosave();
              },
      );
    }
    return null;
  }
}
