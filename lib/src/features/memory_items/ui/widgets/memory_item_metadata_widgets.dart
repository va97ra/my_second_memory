part of '../memory_item_detail_screen.dart';

class _EditorBody extends StatelessWidget {
  const _EditorBody({
    required this.selectedType,
    required this.dateText,
    required this.timeText,
    required this.reminderEnabled,
    required this.onDateTap,
    required this.onTimeTap,
    required this.onClearTime,
    required this.onTypeChanged,
    required this.specialFields,
    required this.showRecurrenceHint,
    required this.onRecurrenceHintTap,
    required this.recordEditor,
  });

  final MemoryType selectedType;
  final String dateText;
  final String? timeText;
  final bool reminderEnabled;
  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;
  final VoidCallback? onClearTime;
  final ValueChanged<MemoryType> onTypeChanged;
  final Widget? specialFields;
  final bool showRecurrenceHint;
  final VoidCallback onRecurrenceHintTap;
  final Widget recordEditor;

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = keyboardVisible || constraints.maxHeight < 520;
        final bottomPadding = keyboardVisible ? 8.0 : 24.0;

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
              child: Column(
                children: [
                  _EditorMetadataBar(
                    selectedType: selectedType,
                    dateText: dateText,
                    timeText: timeText,
                    reminderEnabled: reminderEnabled,
                    onDateTap: onDateTap,
                    onTimeTap: onTimeTap,
                    onClearTime: onClearTime,
                    onTypeChanged: onTypeChanged,
                  ),
                  if (specialFields != null) ...[
                    SizedBox(height: compact ? 6 : 8),
                    specialFields!,
                  ],
                  if (showRecurrenceHint) ...[
                    SizedBox(height: compact ? 6 : 8),
                    _RecurrenceHint(onTap: onRecurrenceHintTap),
                  ],
                  SizedBox(height: compact ? 8 : 10),
                  Expanded(child: recordEditor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RecurrenceHint extends StatelessWidget {
  const _RecurrenceHint({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ru = Localizations.localeOf(context).languageCode == 'ru';
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.primaryContainer.withValues(alpha: 0.38),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colors.primary.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            children: [
              Icon(Icons.event_repeat, size: 17, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ru
                      ? 'Чтобы повторять запись, нажмите ↻ в правом верхнем углу.'
                      : 'To repeat a record, tap ↻ in the top-right corner.',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorMetadataBar extends StatelessWidget {
  const _EditorMetadataBar({
    required this.selectedType,
    required this.dateText,
    required this.timeText,
    required this.reminderEnabled,
    required this.onDateTap,
    required this.onTimeTap,
    required this.onClearTime,
    required this.onTypeChanged,
  });

  final MemoryType selectedType;
  final String dateText;
  final String? timeText;
  final bool reminderEnabled;
  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;
  final VoidCallback? onClearTime;
  final ValueChanged<MemoryType> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final typeColor = memoryTypeColor(selectedType);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B4F35).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              flex: 11,
              child: _MetadataAction(
                key: const ValueKey('memory_type_picker'),
                icon: memoryTypeIcon(selectedType),
                label: strings.recordType,
                value: selectedType.label(locale),
                color: typeColor,
                onTap: () => _showTypePicker(context),
              ),
            ),
            const _MetadataDivider(),
            Expanded(
              flex: 10,
              child: _MetadataAction(
                key: const ValueKey('memory_date_picker'),
                icon: Icons.event_outlined,
                label: strings.date,
                value: dateText,
                color: const Color(0xFFC98A70),
                onTap: onDateTap,
              ),
            ),
            const _MetadataDivider(),
            Expanded(
              flex: 9,
              child: _MetadataAction(
                key: const ValueKey('memory_time_picker'),
                icon: Icons.schedule_outlined,
                label: strings.time,
                value: timeText ?? strings.timeNotSet,
                isPlaceholder: timeText == null,
                color: const Color(0xFFC98A70),
                onTap: onTimeTap,
                onClear: onClearTime,
                badgeIcon: reminderEnabled ? Icons.notifications_active : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTypePicker(BuildContext context) async {
    final selected = await showModalBottomSheet<MemoryType>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        final locale = Localizations.localeOf(context).languageCode;
        final strings = AppStrings.of(context);

        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                child: Text(
                  strings.recordType,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              for (final type in editableMemoryTypes)
                _TypePickerRow(
                  type: type,
                  label: type.label(locale),
                  selected: type == selectedType,
                  onTap: () => Navigator.of(context).pop(type),
                ),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      onTypeChanged(selected);
    }
  }
}

class _RecurrenceBadge extends StatelessWidget {
  const _RecurrenceBadge({
    required this.frequency,
    required this.onTap,
  });

  final RecurrenceFrequency frequency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colors.primary.withValues(alpha: 0.38)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_repeat,
                size: 17,
                color: colors.onPrimaryContainer,
              ),
              const SizedBox(width: 6),
              Text(
                frequency.label(locale),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentFields extends StatelessWidget {
  const _PaymentFields({
    required this.amountController,
    required this.category,
    required this.locale,
    required this.onCategoryChanged,
    required this.onChanged,
  });

  final TextEditingController amountController;
  final PaymentCategory category;
  final String locale;
  final ValueChanged<PaymentCategory> onCategoryChanged;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 42),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<PaymentCategory>(
                value: category,
                isExpanded: true,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                items: [
                  for (final value in PaymentCategory.values)
                    DropdownMenuItem(
                      value: value,
                      child: Text(value.label(locale),
                          overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) onCategoryChanged(value);
                },
              ),
            ),
          ),
          Container(
            width: 1,
            height: 28,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          SizedBox(
            width: 104,
            child: TextField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.end,
              decoration: InputDecoration(
                hintText: locale == 'ru' ? 'Сумма ₽' : 'Amount ₽',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
        ],
      ),
    );
  }
}

class _BirthdayFields extends StatelessWidget {
  const _BirthdayFields({
    required this.birthYear,
    required this.locale,
    required this.onTap,
    required this.onClear,
  });

  final int? birthYear;
  final String locale;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 42),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              const Icon(Icons.cake_outlined, size: 18),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  birthYear == null
                      ? (locale == 'ru' ? 'Год рождения' : 'Birth year')
                      : birthYear.toString(),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onClear != null)
                IconButton(
                  tooltip: AppStrings.of(context).delete,
                  onPressed: onClear,
                  icon: const Icon(Icons.close, size: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetadataDivider extends StatelessWidget {
  const _MetadataDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

class _MetadataAction extends StatelessWidget {
  const _MetadataAction({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
    this.isPlaceholder = false,
    this.onClear,
    this.badgeIcon,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isPlaceholder;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final IconData? badgeIcon;

  @override
  Widget build(BuildContext context) {
    final valueColor = isPlaceholder ? const Color(0xFF7C746B) : color;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
          child: Row(
            children: [
              Icon(icon, size: 17, color: valueColor),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            height: 1,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: valueColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                    ),
                  ],
                ),
              ),
              if (badgeIcon != null)
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Icon(
                    badgeIcon,
                    key: const ValueKey('memory_reminder_enabled'),
                    size: 14,
                    color: const Color(0xFF168653),
                  ),
                ),
              if (onClear != null)
                Tooltip(
                  message: AppStrings.of(context).delete,
                  child: InkResponse(
                    onTap: onClear,
                    radius: 14,
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(Icons.close, size: 13),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
