import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
import '../../../shared/ui/empty_state.dart';
import '../../../shared/ui/screen_chrome.dart';
import '../../calendar/state/calendar_preferences_controller.dart';
import '../../memory_items/domain/memory_type.dart';
import '../../memory_items/state/memory_items_controller.dart';
import '../../memory_items/state/memory_item_selectors.dart';
import '../../recurrence/ui/recurring_informers.dart';
import '../domain/feed_rules.dart';
import '../state/feed_providers.dart';
import 'widgets/memory_item_card.dart';

class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
  static const _dividerHeight = 48.0;

  final Set<String> _expandedPastDays = <String>{};
  final ScrollController _scrollController = ScrollController();
  bool _notesExpanded = false;
  bool _initialTodayFocusScheduled = false;
  bool _branchWasActive = false;
  int _futureDayCount = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final branchIsActive = TickerMode.valuesOf(context).enabled;
    if (branchIsActive && !_branchWasActive && _initialTodayFocusScheduled) {
      _scheduleTodayFocus(force: true);
    }
    _branchWasActive = branchIsActive;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final loadState = ref.watch(memoryItemsLoadProvider);
    final filter = ref.watch(feedFilterProvider);
    final layout = ref.watch(feedLayoutProvider);
    final notes = ref.watch(undatedNotesProvider);
    final isEmpty = layout.days.isEmpty && notes.isEmpty;
    final showHints = ref.watch(appHintsProvider);
    final mediaQuery = MediaQuery.of(context);
    final showFeedHint = showHints &&
        mediaQuery.size.height >= 720 &&
        mediaQuery.textScaler.scale(1) <= 1.3;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final futureDayCount = layout.days.where((group) {
      final date = DateTime(group.date.year, group.date.month, group.date.day);
      return date.isAfter(today);
    }).length;
    _futureDayCount = futureDayCount;

    if (loadState.isLoading || loadState.hasError) {
      return WarmGradientBackground(
        child: CustomScrollView(
          slivers: [
            MainSliverAppBar(title: strings.dayFeed),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: loadState.isLoading
                    ? const CircularProgressIndicator()
                    : Text(strings.loadFailed),
              ),
            ),
          ],
        ),
      );
    }

    _scheduleTodayFocus();

    return WarmGradientBackground(
      child: Column(
        children: [
          _FeedHeader(
            title: strings.dayFeed,
            filter: filter,
            onFilterSelected: (filter) {
              ref.read(feedFilterProvider.notifier).state = filter;
            },
          ),
          if (showFeedHint) const _FeedUsageHint(),
          const KeyedSubtree(
            key: ValueKey('feed_recurring_informers'),
            child: RecurringInformers(height: 164),
          ),
          _FeedDayDivider(
            key: const ValueKey('feed_notes_divider'),
            label: '${strings.notes} · ${notes.length}',
            expanded: _notesExpanded,
            collapsible: true,
            onTap: _toggleNotes,
          ),
          if (_notesExpanded)
            _UndatedNotesList(itemIds: [
              for (final note in notes) note.id,
            ]),
          Expanded(
            child: CustomScrollView(
              key: const ValueKey('feed_dated_scroll'),
              controller: _scrollController,
              slivers: [
                if (isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: AppEmptyState(
                        icon: Icons.view_agenda_rounded,
                        title: strings.emptyFeed,
                        actionLabel: strings.addRecord,
                        onAction: () => context.go('/calendar'),
                      ),
                    ),
                  )
                else
                  for (final group in layout.days)
                    ..._buildDaySlivers(
                      context,
                      date: group.date,
                      itemIds: group.itemIds,
                    ),
                SliverPadding(
                  padding: EdgeInsets.only(
                    bottom: futureDayCount > 0
                        ? MediaQuery.sizeOf(context).height
                        : 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _scheduleTodayFocus({bool force = false}) {
    if (_initialTodayFocusScheduled && !force) return;
    _initialTodayFocusScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final target = _futureDayCount * _dividerHeight;
      final position = _scrollController.position;
      _scrollController.jumpTo(
        target.clamp(position.minScrollExtent, position.maxScrollExtent),
      );
    });
  }

  void _toggleNotes() {
    setState(() => _notesExpanded = !_notesExpanded);
  }

  List<Widget> _buildDaySlivers(
    BuildContext context, {
    required DateTime date,
    required List<String> itemIds,
  }) {
    final key = _feedDateKey(date);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checked = DateTime(date.year, date.month, date.day);
    final isToday = checked == today;
    final isExpanded = isToday || _expandedPastDays.contains(key);
    final strings = AppStrings.of(context);
    final dateLabel = _feedDividerLabel(context, date);
    final label = isToday
        ? dateLabel
        : '$dateLabel · ${strings.recordsCount(itemIds.length)}';

    return [
      SliverToBoxAdapter(
        child: _FeedDayDivider(
          key: ValueKey('feed_day_divider_$key'),
          label: label,
          expanded: isExpanded,
          collapsible: !isToday,
          onTap: isToday
              ? null
              : () {
                  setState(() {
                    if (isExpanded) {
                      _expandedPastDays.remove(key);
                    } else {
                      _expandedPastDays.add(key);
                    }
                  });
                },
        ),
      ),
      if (isExpanded) _MemorySliverList(itemIds: itemIds),
    ];
  }
}

class _FeedDayDivider extends StatelessWidget {
  const _FeedDayDivider({
    required this.label,
    required this.expanded,
    required this.collapsible,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool expanded;
  final bool collapsible;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final divider = AppLabeledDivider(
      label: label,
      trailingIcon: collapsible
          ? expanded
              ? Icons.expand_less_rounded
              : Icons.expand_more_rounded
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 16),
    );
    if (!collapsible) return divider;
    return Semantics(
      button: true,
      expanded: expanded,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(height: 48, child: Center(child: divider)),
        ),
      ),
    );
  }
}

String _feedDividerLabel(BuildContext context, DateTime date) {
  final strings = AppStrings.of(context);
  final locale = Localizations.localeOf(context).languageCode;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final checked = DateTime(date.year, date.month, date.day);
  final shortDate = DateFormat(
    locale == 'ru' ? 'd MMMM' : 'MMMM d',
    locale,
  ).format(checked);
  if (checked == today) return '${strings.today} · $shortDate';
  if (checked == today.subtract(const Duration(days: 1))) {
    return '${strings.yesterday} · $shortDate';
  }
  return DateFormat(
    locale == 'ru' ? 'd MMMM y' : 'MMMM d, y',
    locale,
  ).format(checked);
}

String _feedDateKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

class _FeedHeader extends StatelessWidget {
  const _FeedHeader({
    required this.title,
    required this.filter,
    required this.onFilterSelected,
  });

  final String title;
  final FeedFilter filter;
  final ValueChanged<FeedFilter> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            _FeedFilterButton(
              selected: filter,
              onSelected: onFilterSelected,
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedUsageHint extends StatelessWidget {
  const _FeedUsageHint();

  @override
  Widget build(BuildContext context) {
    final ru = Localizations.localeOf(context).languageCode == 'ru';
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
      child: Material(
        color: colors.primaryContainer.withValues(alpha: 0.42),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colors.primary.withValues(alpha: 0.32)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ru ? 'Как пользоваться' : 'How to use the app',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 5),
              _HintLine(
                icon: Icons.calendar_month_rounded,
                text: ru
                    ? 'Календарь → дата → «Добавить запись»'
                    : 'Calendar → date → Add record',
              ),
              _HintLine(
                icon: Icons.event_repeat_rounded,
                text: ru
                    ? '↻ включает повтор, галочка завершает запись'
                    : '↻ repeats; the check mark completes a record',
              ),
              _HintLine(
                icon: Icons.archive_rounded,
                text: ru
                    ? 'Архив переносит запись в Архив памяти'
                    : 'Archive moves a record to Memory archive',
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showFullGuide(context, ru),
                  icon: const Icon(Icons.menu_book_rounded, size: 17),
                  label: Text(
                    ru ? 'Все возможности' : 'All features',
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                ru
                    ? 'Подсказки отключаются в Настройки → Показывать подсказки.'
                    : 'Turn hints off in Settings → Show hints.',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showFullGuide(BuildContext context, bool ru) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _FullGuideSheet(ru: ru),
    );
  }
}

class _FullGuideSheet extends StatelessWidget {
  const _FullGuideSheet({required this.ru});

  final bool ru;

  @override
  Widget build(BuildContext context) {
    final items = <_GuideSection>[
      _GuideSection(
        title: ru ? 'Записи' : 'Records',
        items: [
          _GuideItem(
            Icons.add_box_rounded,
            ru
                ? 'Откройте Календарь, нажмите дату и «Добавить запись».'
                : 'Open Calendar, tap a date, then Add record.',
          ),
          _GuideItem(
            Icons.category_rounded,
            ru
                ? 'Выберите тип: задача, заметка, событие, цель, проект, покупка, документ, место, день рождения или платёж.'
                : 'Choose a record type: task, note, event, goal, project, purchase, document, place, birthday, or payment.',
          ),
          _GuideItem(
            Icons.perm_media_rounded,
            ru
                ? 'Добавляйте текст, фотографии и голос. Изменения сохраняются автоматически.'
                : 'Add text, photos, and voice. Changes are saved automatically.',
          ),
          _GuideItem(
            Icons.touch_app_rounded,
            ru
                ? 'Нажмите фото для полного просмотра. Удерживайте фото или голос, чтобы удалить вложение.'
                : 'Tap a photo for full view. Hold a photo or voice note to remove it.',
          ),
        ],
      ),
      _GuideSection(
        title: ru ? 'Планирование' : 'Planning',
        items: [
          _GuideItem(
            Icons.schedule_rounded,
            ru
                ? 'Укажите дату и время события, при необходимости включите звуковое напоминание и выберите мелодию.'
                : 'Set a date and time, optionally enable a sound reminder and choose a melody.',
          ),
          _GuideItem(
            Icons.repeat_rounded,
            ru
                ? 'Кнопка ↻ создаёт ежемесячный или ежегодный повтор.'
                : 'The ↻ button creates a monthly or yearly recurrence.',
          ),
          _GuideItem(
            Icons.content_copy_rounded,
            ru
                ? 'В меню записи можно дублировать её сразу на несколько дат.'
                : 'The record menu can duplicate it to several dates at once.',
          ),
          _GuideItem(
            Icons.cake_rounded,
            ru
                ? 'Дни рождения повторяются ежегодно, платежи — ежемесячно; календарь показывает праздники.'
                : 'Birthdays repeat yearly, payments monthly, and holidays appear in the calendar.',
          ),
        ],
      ),
      _GuideSection(
        title: ru ? 'Лента и календарь' : 'Feed and calendar',
        items: [
          _GuideItem(
            Icons.edit_note_rounded,
            ru
                ? 'Центральная кнопка «Записка» создаёт запись без даты, которая всегда находится в разделе «Записки» над лентой.'
                : 'The center Note button creates an undated note that stays in the Notes section above the feed.',
          ),
          _GuideItem(
            Icons.filter_list_rounded,
            ru
                ? 'Фильтр ленты помогает показать только нужные типы и состояния записей.'
                : 'Feed filters show only the record types and states you need.',
          ),
          _GuideItem(
            Icons.view_timeline_rounded,
            ru
                ? 'Информеры месяца и года показывают повторяющиеся записи текущего периода.'
                : 'Month and year panels show recurring records for the current period.',
          ),
          _GuideItem(
            Icons.task_alt_rounded,
            ru
                ? 'Галочка завершает запись. Архив скрывает её из ленты, но оставляет в календаре.'
                : 'The check mark completes a record. Archive hides it from the feed but keeps it in the calendar.',
          ),
          _GuideItem(
            Icons.inventory_2_rounded,
            ru
                ? 'Архивные записи находятся в Настройки → Архив памяти, откуда их можно вернуть.'
                : 'Archived records are in Settings → Memory archive and can be restored.',
          ),
          _GuideItem(
            Icons.edit_note_rounded,
            ru
                ? 'Из ленты запись открывается для безопасного просмотра, из календарного дня — для редактирования.'
                : 'The feed opens a safe read-only view; the calendar day opens the editor.',
          ),
        ],
      ),
      _GuideSection(
        title: ru ? 'Дополнительные возможности' : 'More features',
        items: [
          _GuideItem(
            Icons.vpn_key_rounded,
            ru
                ? 'Во вкладке Аккаунты можно хранить сервисы, логины, email, пароли, сайты и заметки.'
                : 'Accounts stores services, logins, email addresses, passwords, websites, and notes.',
          ),
          _GuideItem(
            Icons.work_history_rounded,
            ru
                ? 'Графики смен поддерживают 5/2, 2/2 и сутки/трое, цвета календаря и два будильника.'
                : 'Shift schedules support 5/2, 2/2, and 1/3 patterns, calendar colors, and two alarms.',
          ),
          _GuideItem(
            Icons.cloud_upload_rounded,
            ru
                ? 'Резервная копия сохраняет зашифрованный архив в папку Загрузки и позволяет восстановить данные.'
                : 'Backup saves an encrypted archive to Downloads and restores your data.',
          ),
          _GuideItem(
            Icons.lock_rounded,
            ru
                ? 'PIN шифрует данные приложения, а биометрия позволяет входить без показа PIN-экрана.'
                : 'PIN encrypts app data, while biometrics unlocks without showing the PIN screen.',
          ),
          _GuideItem(
            Icons.palette_rounded,
            ru
                ? 'В настройках доступны язык, темы, шрифт записей, праздники и подсказки.'
                : 'Settings includes language, themes, record fonts, holidays, and hints.',
          ),
        ],
      ),
    ];

    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    ru ? 'Возможности приложения' : 'App features',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: ru ? 'Закрыть' : 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              itemCount: items.length,
              itemBuilder: (context, index) => _GuideSectionView(
                section: items[index],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideSectionView extends StatelessWidget {
  const _GuideSectionView({required this.section});

  final _GuideSection section;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 5),
          for (final item in section.items)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              minLeadingWidth: 28,
              leading: Icon(item.icon, size: 20, color: colors.primary),
              title: Text(
                item.text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GuideSection {
  const _GuideSection({required this.title, required this.items});

  final String title;
  final List<_GuideItem> items;
}

class _GuideItem {
  const _GuideItem(this.icon, this.text);

  final IconData icon;
  final String text;
}

class _HintLine extends StatelessWidget {
  const _HintLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Icon(icon, size: 15, color: colors.primary),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedFilterButton extends StatelessWidget {
  const _FeedFilterButton({
    required this.selected,
    required this.onSelected,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 4),
  });

  final FeedFilter selected;
  final ValueChanged<FeedFilter> onSelected;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final label = _labelFor(context, selected);
    final maxButtonWidth =
        (MediaQuery.sizeOf(context).width * 0.62).clamp(156.0, 240.0);

    return Padding(
      padding: padding,
      child: Align(
        alignment: Alignment.centerLeft,
        child: PopupMenuButton<FeedFilter>(
          tooltip: strings.feedFilter,
          initialValue: selected,
          onSelected: onSelected,
          itemBuilder: (context) {
            return [
              for (final filter in FeedFilter.values)
                PopupMenuItem(
                  value: filter,
                  child: Row(
                    children: [
                      Icon(
                        _iconFor(filter),
                        size: 19,
                        color: filter == selected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      Text(_labelFor(context, filter)),
                    ],
                  ),
                ),
            ];
          },
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxButtonWidth),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.expand_more_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _labelFor(BuildContext context, FeedFilter filter) {
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context).languageCode;

    return switch (filter) {
      FeedFilter.all => strings.allRecords,
      FeedFilter.active => strings.activeRecords,
      FeedFilter.done => strings.completedRecords,
      FeedFilter.task => MemoryType.task.label(locale),
      FeedFilter.note => MemoryType.note.label(locale),
      FeedFilter.event => MemoryType.event.label(locale),
      FeedFilter.goal => MemoryType.goal.label(locale),
      FeedFilter.project => MemoryType.project.label(locale),
      FeedFilter.purchase => MemoryType.purchase.label(locale),
      FeedFilter.document => MemoryType.document.label(locale),
      FeedFilter.place => MemoryType.place.label(locale),
      FeedFilter.birthday => MemoryType.birthday.label(locale),
      FeedFilter.payment => MemoryType.payment.label(locale),
    };
  }

  IconData _iconFor(FeedFilter filter) {
    return switch (filter) {
      FeedFilter.all => Icons.view_agenda_rounded,
      FeedFilter.active => Icons.radio_button_unchecked_rounded,
      FeedFilter.done => Icons.task_alt_rounded,
      FeedFilter.task => Icons.task_alt_rounded,
      FeedFilter.note => Icons.sticky_note_2_rounded,
      FeedFilter.event => Icons.event_rounded,
      FeedFilter.goal => Icons.flag_rounded,
      FeedFilter.project => Icons.folder_rounded,
      FeedFilter.purchase => Icons.shopping_bag_rounded,
      FeedFilter.document => Icons.description_rounded,
      FeedFilter.place => Icons.location_on_rounded,
      FeedFilter.birthday => Icons.cake_rounded,
      FeedFilter.payment => Icons.payments_rounded,
    };
  }
}

class _MemorySliverList extends StatelessWidget {
  const _MemorySliverList({
    required this.itemIds,
  });

  final List<String> itemIds;

  @override
  Widget build(BuildContext context) {
    if (itemIds.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverList.builder(
      itemCount: itemIds.length,
      itemBuilder: (context, index) {
        return _FeedMemoryCard(
          itemId: itemIds[index],
        );
      },
    );
  }
}

class _UndatedNotesList extends StatelessWidget {
  const _UndatedNotesList({required this.itemIds});

  final List<String> itemIds;

  @override
  Widget build(BuildContext context) {
    if (itemIds.isEmpty) return const SizedBox.shrink();

    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final estimatedCardHeight = textScale <= 1.3
        ? 76 + ((textScale - 1).clamp(0.0, 0.3) * 40)
        : 88 + (((textScale - 1.3) / 0.7).clamp(0.0, 1.0) * 64);
    final contentHeight = itemIds.length * (estimatedCardHeight + 8);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.32;

    return SizedBox(
      height: contentHeight.clamp(0.0, maxHeight),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: itemIds.length,
        itemBuilder: (context, index) => _UndatedNoteCard(
          itemId: itemIds[index],
        ),
      ),
    );
  }
}

class _UndatedNoteCard extends ConsumerWidget {
  const _UndatedNoteCard({required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(memoryItemByIdProvider(itemId));
    if (item == null) return const SizedBox.shrink();
    return MemoryItemCard(
      item: item,
      showDate: false,
      compact: true,
      denseFeedLayout: true,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      onOpen: () =>
          context.push('/memory/view/${Uri.encodeComponent(item.id)}'),
      onArchive: () {
        ref.read(memoryItemsControllerProvider.notifier).archive(item.id);
      },
    );
  }
}

class _FeedMemoryCard extends ConsumerWidget {
  const _FeedMemoryCard({
    required this.itemId,
  });

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(memoryItemByIdProvider(itemId));
    if (item == null) return const SizedBox.shrink();
    return MemoryItemCard(
      item: item,
      showDate: false,
      compact: true,
      denseFeedLayout: true,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      onOpen: () {
        context.push('/memory/view/${Uri.encodeComponent(item.id)}');
      },
      onToggleDone: () {
        ref.read(memoryItemsControllerProvider.notifier).toggleDone(item.id);
      },
      onArchive: () {
        ref.read(memoryItemsControllerProvider.notifier).archive(item.id);
      },
    );
  }
}
