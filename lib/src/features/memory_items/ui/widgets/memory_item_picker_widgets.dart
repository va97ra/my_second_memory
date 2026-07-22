part of '../memory_item_detail_screen.dart';

class _TypePickerRow extends StatelessWidget {
  const _TypePickerRow({
    required this.type,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final MemoryType type;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = memoryTypeColor(type);

    final row = Material(
      color: selected
          ? color.withValues(alpha: 0.12)
          : Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected
              ? color.withValues(alpha: 0.36)
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            SizedBox(
              width: 5,
              height: double.infinity,
              child: ColoredBox(color: color),
            ),
            const SizedBox(width: 11),
            Icon(memoryTypeIcon(type), color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: color, size: 20),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: NotebookPressable(onTap: onTap, child: row),
    );
  }
}

class _MultiDatePickerSheet extends StatefulWidget {
  const _MultiDatePickerSheet({required this.sourceDate});

  final DateTime sourceDate;

  @override
  State<_MultiDatePickerSheet> createState() => _MultiDatePickerSheetState();
}

class _MultiDatePickerSheetState extends State<_MultiDatePickerSheet> {
  late DateTime _month = DateTime(
    widget.sourceDate.year,
    widget.sourceDate.month,
  );
  final Set<int> _selected = {};

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final first = DateTime(_month.year, _month.month, 1);
    final offset = first.weekday - DateTime.monday;
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final cells = ((offset + days + 6) ~/ 7) * 7;
    final weekdays = locale == 'ru'
        ? const ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс']
        : const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.82,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      locale == 'ru'
                          ? 'Дублировать на даты'
                          : 'Duplicate to dates',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _moveMonth(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    DateFormat.yMMMM(locale).format(_month),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  IconButton(
                    onPressed: () => _moveMonth(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              Row(
                children: [
                  for (final day in weekdays)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          day,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemCount: cells,
                  itemBuilder: (context, index) {
                    final day = index - offset + 1;
                    if (day < 1 || day > days) return const SizedBox.shrink();
                    final date = DateTime(_month.year, _month.month, day);
                    final key = _dateKeyForPicker(date);
                    final selected = _selected.contains(key);
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => setState(() {
                        if (!_selected.add(key)) _selected.remove(key);
                      }),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$day',
                            style: TextStyle(
                              color: selected
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _selected.isEmpty
                      ? null
                      : () {
                          final dates = _selected.map((key) {
                            final year = key ~/ 10000;
                            final month = (key ~/ 100) % 100;
                            return DateTime(year, month, key % 100);
                          }).toList()
                            ..sort();
                          Navigator.of(context).pop(dates);
                        },
                  icon: const Icon(Icons.copy_all_outlined),
                  label: Text(
                    locale == 'ru'
                        ? 'Создать копии (${_selected.length})'
                        : 'Create copies (${_selected.length})',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _moveMonth(int offset) {
    setState(() => _month = DateTime(_month.year, _month.month + offset));
  }
}

int _dateKeyForPicker(DateTime value) =>
    value.year * 10000 + value.month * 100 + value.day;
