import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
import '../../../shared/ui/app_shell.dart';
import '../../home_feed/domain/feed_rules.dart';
import '../../home_feed/ui/widgets/memory_image_preview.dart';
import '../../home_feed/ui/widgets/memory_item_card.dart';
import '../../memory_items/domain/memory_item.dart';
import '../../memory_items/domain/memory_type.dart';
import '../../memory_items/state/memory_items_controller.dart';
import '../../memory_items/ui/widgets/memory_type_picker.dart';
import '../../voice_notes/ui/widgets/voice_note_recorder.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _visibleMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final items = ref
        .watch(memoryItemsControllerProvider)
        .where((item) => !item.isArchived)
        .toList();

    return AppShell(
      currentIndex: 1,
      child: CustomScrollView(
        slivers: [
          SliverAppBar.large(title: Text(strings.calendar)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: _CalendarPanel(
                locale: locale,
                visibleMonth: _visibleMonth,
                selectedDate: _selectedDate,
                items: items,
                onPreviousMonth: () => setState(() {
                  _visibleMonth = DateTime(
                    _visibleMonth.year,
                    _visibleMonth.month - 1,
                  );
                }),
                onNextMonth: () => setState(() {
                  _visibleMonth = DateTime(
                    _visibleMonth.year,
                    _visibleMonth.month + 1,
                  );
                }),
                onSelectDate: _openDayDialog,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDayDialog(DateTime date) async {
    final selected = DateTime(date.year, date.month, date.day);
    setState(() {
      _selectedDate = selected;
      _visibleMonth = DateTime(selected.year, selected.month);
    });

    await showDialog<void>(
      context: context,
      builder: (context) => _DayEditorDialog(date: selected),
    );
  }
}

class _DayEditorDialog extends ConsumerStatefulWidget {
  const _DayEditorDialog({required this.date});

  final DateTime date;

  @override
  ConsumerState<_DayEditorDialog> createState() => _DayEditorDialogState();
}

class _DayEditorDialogState extends ConsumerState<_DayEditorDialog> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  MemoryType _type = MemoryType.note;
  String? _audioPath;
  int? _audioDurationSeconds;
  final _imagePaths = <String>[];

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final dayItems = ref
        .watch(memoryItemsControllerProvider)
        .where((item) => !item.isArchived && isSameDay(item.memoryDate, widget.date))
        .toList();

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat.yMMMMEEEEd(locale).format(widget.date),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: [
                    Text(
                      strings.dayRecords,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (dayItems.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(strings.emptyFeed),
                      )
                    else
                      for (final item in dayItems)
                        MemoryItemCard(
                          item: item,
                          onDelete: () {
                            ref
                                .read(memoryItemsControllerProvider.notifier)
                                .delete(item.id);
                          },
                        ),
                    const SizedBox(height: 12),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          MemoryTypePicker(
                            selected: _type,
                            onSelected: (type) => setState(() => _type = type),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _titleController,
                            decoration: InputDecoration(labelText: strings.title),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return strings.title;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _bodyController,
                            decoration:
                                InputDecoration(labelText: strings.description),
                            minLines: 2,
                            maxLines: 4,
                          ),
                          if (_type == MemoryType.voiceNote) ...[
                            const SizedBox(height: 10),
                            VoiceNoteRecorder(
                              onSaved: (path, duration) {
                                setState(() {
                                  _audioPath = path;
                                  _audioDurationSeconds = duration;
                                });
                              },
                            ),
                          ],
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.image_outlined),
                            label: Text(strings.addImage),
                          ),
                          if (_imagePaths.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _AttachedImageStrip(
                              paths: _imagePaths,
                              onRemove: (path) {
                                setState(() => _imagePaths.remove(path));
                              },
                            ),
                          ],
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _save,
                            icon: const Icon(Icons.save_outlined),
                            label: Text(strings.save),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    const imageGroup = XTypeGroup(
      label: 'Images',
      extensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
    );
    final file = await openFile(acceptedTypeGroups: [imageGroup]);
    if (file == null) {
      return;
    }

    setState(() => _imagePaths.add(file.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_type == MemoryType.voiceNote && _audioPath == null) {
      final strings = AppStrings.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.recordAudioBeforeSaving)),
      );
      return;
    }

    final now = DateTime.now();
    final item = MemoryItem(
      id: now.microsecondsSinceEpoch.toString(),
      type: _type,
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      memoryDate: widget.date,
      createdAt: now,
      updatedAt: now,
      audioPath: _audioPath,
      audioDurationSeconds: _audioDurationSeconds,
      imagePaths: List.unmodifiable(_imagePaths),
    );

    await ref.read(memoryItemsControllerProvider.notifier).add(item);

    if (!mounted) {
      return;
    }

    _titleController.clear();
    _bodyController.clear();
    setState(() {
      _type = MemoryType.note;
      _audioPath = null;
      _audioDurationSeconds = null;
      _imagePaths.clear();
    });
  }
}

class _AttachedImageStrip extends StatelessWidget {
  const _AttachedImageStrip({
    required this.paths,
    required this.onRemove,
  });

  final List<String> paths;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: paths.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final path = paths[index];
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 120,
                  height: 88,
                  child: MemoryImagePreview(path: path),
                ),
              ),
              Positioned(
                right: 4,
                top: 4,
                child: IconButton.filledTonal(
                  constraints: const BoxConstraints.tightFor(
                    width: 28,
                    height: 28,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: () => onRemove(path),
                  icon: const Icon(Icons.close, size: 16),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CalendarPanel extends StatelessWidget {
  const _CalendarPanel({
    required this.locale,
    required this.visibleMonth,
    required this.selectedDate,
    required this.items,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onSelectDate,
  });

  final String locale;
  final DateTime visibleMonth;
  final DateTime selectedDate;
  final List<MemoryItem> items;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final days = _daysForMonth(visibleMonth);
    final weekDays = _weekDayLabels(locale);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Previous month',
                  onPressed: onPreviousMonth,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    _capitalize(DateFormat.yMMMM(locale).format(visibleMonth)),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Next month',
                  onPressed: onNextMonth,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                for (final label in weekDays)
                  Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                return _CalendarDayCell(
                  date: day,
                  isInVisibleMonth: day.month == visibleMonth.month,
                  isSelected: isSameDay(day, selectedDate),
                  isToday: isSameDay(day, DateTime.now()),
                  itemCount: _itemsForDay(day).length,
                  onTap: () => onSelectDate(day),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<MemoryItem> _itemsForDay(DateTime date) {
    return items.where((item) => isSameDay(item.memoryDate, date)).toList();
  }

  List<DateTime> _daysForMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month);
    final leadingDays = firstDay.weekday - DateTime.monday;
    final start = firstDay.subtract(Duration(days: leadingDays));

    return [
      for (var index = 0; index < 42; index++)
        DateTime(start.year, start.month, start.day + index),
    ];
  }

  List<String> _weekDayLabels(String locale) {
    if (locale == 'ru') {
      return const ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    }
    return const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  }

  String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.isInVisibleMonth,
    required this.isSelected,
    required this.isToday,
    required this.itemCount,
    required this.onTap,
  });

  final DateTime date;
  final bool isInVisibleMonth;
  final bool isSelected;
  final bool isToday;
  final int itemCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = isSelected
        ? colors.onPrimary
        : isInVisibleMonth
            ? colors.onSurface
            : colors.onSurface.withValues(alpha: 0.38);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary
              : isToday
                  ? const Color(0xFFEAF3FF)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? colors.primary
                : isToday
                    ? const Color(0xFF93C5FD)
                    : Colors.transparent,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                '${date.day}',
                style: TextStyle(
                  color: foreground,
                  fontWeight: isSelected || isToday
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ),
            if (itemCount > 0)
              Positioned(
                right: 5,
                bottom: 5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: isSelected ? colors.onPrimary : colors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: SizedBox(
                    width: 6,
                    height: 6,
                    child: itemCount > 1
                        ? Center(
                            child: Text(
                              itemCount > 9 ? '9' : '$itemCount',
                              style: TextStyle(
                                color: isSelected
                                    ? colors.primary
                                    : colors.onPrimary,
                                fontSize: 6,
                                height: 1,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
