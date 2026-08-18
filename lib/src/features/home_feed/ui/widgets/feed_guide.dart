part of '../home_feed_screen.dart';

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
