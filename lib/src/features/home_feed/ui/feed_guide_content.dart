import 'package:flutter/material.dart';

/// Раздел путеводителя по приложению.
class FeedGuideSection {
  const FeedGuideSection({required this.title, required this.items});

  final String title;
  final List<FeedGuideItem> items;
}

/// Одна строка путеводителя: значок и объяснение.
class FeedGuideItem {
  const FeedGuideItem(this.icon, this.text);

  final IconData icon;
  final String text;
}

/// Текст путеводителя. Это таблица строк интерфейса: добавить пункт — значит
/// добавить запись, ничего больше не трогая.
List<FeedGuideSection> feedGuideSections({required bool ru}) => [
      FeedGuideSection(
        title: ru ? 'Записи' : 'Records',
        items: [
          FeedGuideItem(
            Icons.add_box_rounded,
            ru
                ? 'Откройте Календарь, нажмите дату и «Добавить запись».'
                : 'Open Calendar, tap a date, then Add record.',
          ),
          FeedGuideItem(
            Icons.category_rounded,
            ru
                ? 'Выберите тип: задача, заметка, событие, цель, проект, покупка, документ, место, день рождения или платёж.'
                : 'Choose a record type: task, note, event, goal, project, purchase, document, place, birthday, or payment.',
          ),
          FeedGuideItem(
            Icons.perm_media_rounded,
            ru
                ? 'Добавляйте текст, фотографии и голос. Изменения сохраняются автоматически.'
                : 'Add text, photos, and voice. Changes are saved automatically.',
          ),
          FeedGuideItem(
            Icons.touch_app_rounded,
            ru
                ? 'Нажмите фото для полного просмотра. Удерживайте фото или голос, чтобы удалить вложение.'
                : 'Tap a photo for full view. Hold a photo or voice note to remove it.',
          ),
        ],
      ),
      FeedGuideSection(
        title: ru ? 'Планирование' : 'Planning',
        items: [
          FeedGuideItem(
            Icons.schedule_rounded,
            ru
                ? 'Укажите дату и время события, при необходимости включите звуковое напоминание и выберите мелодию.'
                : 'Set a date and time, optionally enable a sound reminder and choose a melody.',
          ),
          FeedGuideItem(
            Icons.repeat_rounded,
            ru
                ? 'Кнопка ↻ создаёт ежемесячный или ежегодный повтор.'
                : 'The ↻ button creates a monthly or yearly recurrence.',
          ),
          FeedGuideItem(
            Icons.content_copy_rounded,
            ru
                ? 'В меню записи можно дублировать её сразу на несколько дат.'
                : 'The record menu can duplicate it to several dates at once.',
          ),
          FeedGuideItem(
            Icons.cake_rounded,
            ru
                ? 'Дни рождения повторяются ежегодно, платежи — ежемесячно; календарь показывает праздники.'
                : 'Birthdays repeat yearly, payments monthly, and holidays appear in the calendar.',
          ),
        ],
      ),
      FeedGuideSection(
        title: ru ? 'Лента и календарь' : 'Feed and calendar',
        items: [
          FeedGuideItem(
            Icons.edit_note_rounded,
            ru
                ? 'Центральная кнопка «Записка» создаёт запись без даты. Она находится на отдельной закладке «Записки».'
                : 'The center Note button creates an undated note. It appears on the separate Notes tab.',
          ),
          FeedGuideItem(
            Icons.filter_list_rounded,
            ru
                ? 'Фильтр ленты помогает показать только нужные типы и состояния записей.'
                : 'Feed filters show only the record types and states you need.',
          ),
          FeedGuideItem(
            Icons.view_timeline_rounded,
            ru
                ? '«День» показывает обычные записи выбранной даты. «Месяц» и «Год» — только настроенные ежемесячные и ежегодные повторы.'
                : 'Day shows regular records for the selected date. Month and Year show only configured monthly and yearly recurrences.',
          ),
          FeedGuideItem(
            Icons.task_alt_rounded,
            ru
                ? 'Галочка завершает запись. Архив скрывает её из ленты, но оставляет в календаре.'
                : 'The check mark completes a record. Archive hides it from the feed but keeps it in the calendar.',
          ),
          FeedGuideItem(
            Icons.inventory_2_rounded,
            ru
                ? 'Архивные записи находятся в Настройки → Архив памяти, откуда их можно вернуть.'
                : 'Archived records are in Settings → Memory archive and can be restored.',
          ),
          FeedGuideItem(
            Icons.edit_note_rounded,
            ru
                ? 'Из ленты запись открывается для безопасного просмотра, из календарного дня — для редактирования.'
                : 'The feed opens a safe read-only view; the calendar day opens the editor.',
          ),
        ],
      ),
      FeedGuideSection(
        title: ru ? 'Дополнительные возможности' : 'More features',
        items: [
          FeedGuideItem(
            Icons.vpn_key_rounded,
            ru
                ? 'Во вкладке Аккаунты можно хранить сервисы, логины, email, пароли, сайты и заметки.'
                : 'Accounts stores services, logins, email addresses, passwords, websites, and notes.',
          ),
          FeedGuideItem(
            Icons.work_history_rounded,
            ru
                ? 'Графики смен поддерживают 5/2, 2/2 и сутки/трое, цвета календаря и два будильника.'
                : 'Shift schedules support 5/2, 2/2, and 1/3 patterns, calendar colors, and two alarms.',
          ),
          FeedGuideItem(
            Icons.cloud_upload_rounded,
            ru
                ? 'Резервная копия сохраняет зашифрованный архив в папку Загрузки и позволяет восстановить данные.'
                : 'Backup saves an encrypted archive to Downloads and restores your data.',
          ),
          FeedGuideItem(
            Icons.lock_rounded,
            ru
                ? 'PIN шифрует данные приложения, а биометрия позволяет входить без показа PIN-экрана.'
                : 'PIN encrypts app data, while biometrics unlocks without showing the PIN screen.',
          ),
          FeedGuideItem(
            Icons.palette_rounded,
            ru
                ? 'В настройках доступны язык, темы, шрифт записей, праздники и подсказки.'
                : 'Settings includes language, themes, record fonts, holidays, and hints.',
          ),
        ],
      ),
    ];
