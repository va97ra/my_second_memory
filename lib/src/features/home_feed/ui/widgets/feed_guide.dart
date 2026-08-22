part of '../home_feed_screen.dart';

Future<void> _showFullGuide(BuildContext context, bool ru) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _FullGuideSheet(ru: ru),
  );
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
                ? 'Центральная кнопка «Записка» создаёт запись без даты. Она находится на отдельной закладке «Записки».'
                : 'The center Note button creates an undated note. It appears on the separate Notes tab.',
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
                ? '«День» показывает обычные записи выбранной даты. «Месяц» и «Год» — только настроенные ежемесячные и ежегодные повторы.'
                : 'Day shows regular records for the selected date. Month and Year show only configured monthly and yearly recurrences.',
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
