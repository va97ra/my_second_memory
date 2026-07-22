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
  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final loadState = ref.watch(memoryItemsLoadProvider);
    final filter = ref.watch(feedFilterProvider);
    final layout = ref.watch(feedLayoutProvider);
    final isEmpty = layout.days.isEmpty;
    final showHints = ref.watch(appHintsProvider);

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

    return WarmGradientBackground(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _FeedHeader(
              title: strings.dayFeed,
              filter: filter,
              onFilterSelected: (filter) {
                ref.read(feedFilterProvider.notifier).state = filter;
              },
            ),
          ),
          if (showHints) const SliverToBoxAdapter(child: _FeedUsageHint()),
          const SliverToBoxAdapter(child: RecurringInformers(height: 164)),
          if (isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: AppEmptyState(
                  icon: Icons.dynamic_feed_outlined,
                  title: strings.emptyFeed,
                  actionLabel: strings.addRecord,
                  onAction: () => context.go('/calendar'),
                ),
              ),
            )
          else
            for (final group in layout.days) ...[
              SliverToBoxAdapter(
                child: AppLabeledDivider(
                  label: DateFormat(
                    'd MMMM y',
                    Localizations.localeOf(context).languageCode,
                  ).format(group.date),
                ),
              ),
              _MemorySliverList(itemIds: group.itemIds),
            ],
          const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
        ],
      ),
    );
  }
}

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
                icon: Icons.calendar_month_outlined,
                text: ru
                    ? 'Календарь → дата → «Добавить запись»'
                    : 'Calendar → date → Add record',
              ),
              _HintLine(
                icon: Icons.event_repeat,
                text: ru
                    ? '↻ включает повтор, галочка завершает запись'
                    : '↻ repeats; the check mark completes a record',
              ),
              _HintLine(
                icon: Icons.archive_outlined,
                text: ru
                    ? 'Архив переносит запись в Базу памяти'
                    : 'Archive moves a record to Memory library',
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showFullGuide(context, ru),
                  icon: const Icon(Icons.menu_book_outlined, size: 17),
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
            Icons.add_box_outlined,
            ru
                ? 'Откройте Календарь, нажмите дату и «Добавить запись».'
                : 'Open Calendar, tap a date, then Add record.',
          ),
          _GuideItem(
            Icons.category_outlined,
            ru
                ? 'Выберите тип: задача, заметка, событие, цель, проект, покупка, документ, место, день рождения или платёж.'
                : 'Choose a record type: task, note, event, goal, project, purchase, document, place, birthday, or payment.',
          ),
          _GuideItem(
            Icons.perm_media_outlined,
            ru
                ? 'Добавляйте текст, фотографии и голос. Изменения сохраняются автоматически.'
                : 'Add text, photos, and voice. Changes are saved automatically.',
          ),
          _GuideItem(
            Icons.touch_app_outlined,
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
            Icons.schedule_outlined,
            ru
                ? 'Укажите дату и время события, при необходимости включите звуковое напоминание и выберите мелодию.'
                : 'Set a date and time, optionally enable a sound reminder and choose a melody.',
          ),
          _GuideItem(
            Icons.repeat,
            ru
                ? 'Кнопка ↻ создаёт ежемесячный или ежегодный повтор.'
                : 'The ↻ button creates a monthly or yearly recurrence.',
          ),
          _GuideItem(
            Icons.content_copy_outlined,
            ru
                ? 'В меню записи можно дублировать её сразу на несколько дат.'
                : 'The record menu can duplicate it to several dates at once.',
          ),
          _GuideItem(
            Icons.cake_outlined,
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
            Icons.filter_list,
            ru
                ? 'Фильтр ленты помогает показать только нужные типы и состояния записей.'
                : 'Feed filters show only the record types and states you need.',
          ),
          _GuideItem(
            Icons.view_timeline_outlined,
            ru
                ? 'Информеры месяца и года показывают повторяющиеся записи текущего периода.'
                : 'Month and year panels show recurring records for the current period.',
          ),
          _GuideItem(
            Icons.check_circle_outline,
            ru
                ? 'Галочка завершает запись. Архив скрывает её из ленты, но оставляет в календаре.'
                : 'The check mark completes a record. Archive hides it from the feed but keeps it in the calendar.',
          ),
          _GuideItem(
            Icons.inventory_2_outlined,
            ru
                ? 'Архивные записи находятся в Настройки → База памяти, откуда их можно вернуть.'
                : 'Archived records are in Settings → Memory library and can be restored.',
          ),
          _GuideItem(
            Icons.edit_note_outlined,
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
            Icons.key_outlined,
            ru
                ? 'Во вкладке Аккаунты можно хранить сервисы, логины, email, пароли, сайты и заметки.'
                : 'Accounts stores services, logins, email addresses, passwords, websites, and notes.',
          ),
          _GuideItem(
            Icons.work_history_outlined,
            ru
                ? 'Графики смен поддерживают 5/2, 2/2 и сутки/трое, цвета календаря и два будильника.'
                : 'Shift schedules support 5/2, 2/2, and 1/3 patterns, calendar colors, and two alarms.',
          ),
          _GuideItem(
            Icons.backup_outlined,
            ru
                ? 'Резервная копия сохраняет зашифрованный архив в папку Загрузки и позволяет восстановить данные.'
                : 'Backup saves an encrypted archive to Downloads and restores your data.',
          ),
          _GuideItem(
            Icons.lock_outline,
            ru
                ? 'PIN шифрует данные приложения, а биометрия позволяет входить без показа PIN-экрана.'
                : 'PIN encrypts app data, while biometrics unlocks without showing the PIN screen.',
          ),
          _GuideItem(
            Icons.palette_outlined,
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
                  icon: const Icon(Icons.close),
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
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.expand_more, size: 18),
                ],
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
      FeedFilter.all => Icons.dynamic_feed_outlined,
      FeedFilter.active => Icons.radio_button_unchecked,
      FeedFilter.done => Icons.check_circle_outline,
      FeedFilter.task => Icons.check_circle_outline,
      FeedFilter.note => Icons.notes,
      FeedFilter.event => Icons.event,
      FeedFilter.goal => Icons.flag_outlined,
      FeedFilter.project => Icons.folder_outlined,
      FeedFilter.purchase => Icons.shopping_bag_outlined,
      FeedFilter.document => Icons.description_outlined,
      FeedFilter.place => Icons.place_outlined,
      FeedFilter.birthday => Icons.cake_outlined,
      FeedFilter.payment => Icons.payments_outlined,
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

class _FeedMemoryCard extends ConsumerWidget {
  const _FeedMemoryCard({
    required this.itemId,
  });

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(memoryItemByIdProvider(itemId));
    if (item == null) return const SizedBox.shrink();
    return SizedBox(
      height: 114,
      child: MemoryItemCard(
        item: item,
        showDate: false,
        compact: true,
        margin: const EdgeInsets.fromLTRB(16, 3, 16, 3),
        onOpen: () {
          context.push('/memory/view/${Uri.encodeComponent(item.id)}');
        },
        onToggleDone: () {
          ref.read(memoryItemsControllerProvider.notifier).toggleDone(item.id);
        },
        onArchive: () {
          ref.read(memoryItemsControllerProvider.notifier).archive(item.id);
        },
      ),
    );
  }
}
