# Долг: чем код расходится с картой

Список ведётся вручную и обновляется вместе с кодом. Если строка исчезла из
кода — она исчезает и отсюда; если появилась новая, её сюда дописывают в том
же коммите, а не «потом».

Проверено 24 августа 2026.

## Сверх потолка по делу

Здесь внутри живёт вторая ответственность, и её надо вынести. Это долг, а не
исключение.

```text
packages/ez_data/lib/src/notifications/notification_service.dart      518
   один класс реализует и ReminderScheduler, и ShiftAlarmScheduler

packages/ez_data/lib/src/backup/backup_service.dart                   477
   выгрузка, загрузка и потоковая запись архива

lib/src/features/memory_items/state/memory_items_controller.dart      372
packages/ez_design/lib/src/components/page_turn/page_turn_frame.dart  410
lib/src/features/memory_items/ui/widgets/record_editor.dart           322
lib/src/features/memory_items/state/memory_editor_form.dart           306
```

Плюс мелочь того же рода: `time_reminder_sheet` 273, `theme_picker_sheet` 240,
`page_turn_geometry` 233, `account_editor` 217, `screen_chrome` 188,
`account_card` 174, `multi_date_picker_sheet` 167, `subscription_term_sheet`
166.

## Сверх потолка осознанно

Второй ответственности внутри нет — резать нечего. Правило записано в
[`architecture.md`](architecture.md), раздел «Размерные потолки».

```text
packages/ez_domain/lib/src/calendar/holiday_fixed_table.dart          757
   таблица праздников

packages/ez_core/lib/src/localization/app_strings.dart                407
   строки интерфейса

packages/ez_design/lib/src/themes/app_theme.dart                      406
packages/ez_design/lib/src/themes/notebook/notebook_theme.dart        404
   определения тем

packages/ez_design/lib/src/components/page_turn/page_turn_painter.dart 476
   один painter и его геометрия

lib/src/features/recurrence/state/recurrence_legacy_repair.dart       488
   помеченный ремонт данных прошлых версий

lib/src/features/sync/state/sync_controller_impl.dart                 399
   одна машина состояний подключения к облаку: загрузка, вход, хранилище,
   прогон. Всё остальное из неё уже вынуто — набор синхронизируемых данных,
   планировщик и сам прогон живут отдельно, — а фазы машины делят между собой
   одно состояние и время жизни ключа, и растащить их значит размазать это
   состояние по трём объектам

lib/src/features/recurrence/state/recurrence_series_controller.dart   505
   один инвариант серии, описанный в recurrence.md: настройки серии и правка
   отдельного вхождения держат его вместе. Напоминания, уборка медиа и правила
   дат из него уже вынуты; разложить оставшееся по двум объектам значит
   разложить по двум объектам сам инвариант, а именно так и выросли три
   дефекта повторов
```

## Прочее

- **Семнадцать приватных классов-виджетов внутри `ui/`** — все в файлах из
  первого списка; уйдут вместе с ними.
- **Barrel-файлов нет ни у одной из 10 фич**, поэтому снаружи импортируют
  прямо во внутренности.
- **Тесты лежат в `test/` плоской кучей** — 56 файлов, ни одного в пакетах.
  Карта требует раскладки по слоям.
