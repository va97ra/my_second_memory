# Долг: чем код расходится с картой

Список ведётся вручную и обновляется вместе с кодом. Если строка исчезла из
кода — она исчезает и отсюда; если появилась новая, её сюда дописывают в том
же коммите, а не «потом».

Проверено 12 ноября 2026.

## Сверх потолка осознанно

Второй ответственности внутри нет — резать нечего. Правило записано в
[`architecture.md`](architecture.md), раздел «Размерные потолки».

```text
packages/ez_domain/lib/src/calendar/holiday_fixed_table.dart          659
packages/ez_domain/lib/src/calendar/holiday_observance_table.dart     457
packages/ez_domain/lib/src/calendar/holiday_russian_table.dart        994
   таблицы праздников: официальные, международные дни и праздники России

packages/ez_core/lib/src/localization/app_strings.dart                647
   строки интерфейса

packages/ez_design/lib/src/themes/app_theme.dart                      416
packages/ez_design/lib/src/themes/notebook/notebook_theme.dart        425
   определения тем

packages/ez_design/lib/src/components/page_turn/page_turn_painter.dart 476
   один painter и его геометрия

packages/ez_design/lib/src/components/page_turn/page_turn_frame.dart  300
   одна машина состояний переворота: занять очередь, снять страницу,
   проиграть, отпустить. Её шаги делят между собой снимки и время жизни
   анимации. Загрузка текстуры бумаги, непрозрачный снимок и очередь со своим
   InheritedWidget из неё вынуты

lib/src/features/recurrence/state/recurrence_legacy_repair.dart       488
   помеченный ремонт данных прошлых версий

lib/src/features/sync/state/sync_controller_impl.dart                 407
   одна машина состояний подключения к облаку: загрузка, вход, хранилище,
   прогон, фон, выход посреди прогона. Всё остальное из неё вынуто — набор
   синхронизируемых данных, планировщик, облачный слепок и сам прогон живут
   отдельно, — а фазы машины делят между собой одно состояние и время жизни
   ключа, и растащить их значит размазать это состояние по трём объектам

lib/src/features/recurrence/state/recurrence_series_controller.dart   525
   один инвариант серии, описанный в recurrence.md: настройки серии и правка
   отдельного вхождения держат его вместе. Напоминания, уборка медиа и правила
   дат из него вынуты; разложить оставшееся по двум объектам значит разложить
   по двум объектам сам инвариант, а именно так и выросли три дефекта повторов

lib/src/features/memory_items/state/memory_items_controller.dart      369
   одно хранилище записей и его состояние. Напоминания и уборка файлов из него
   вынуты, осталось само чтение и запись

lib/src/features/memory_items/state/memory_editor_form.dart           324
   одно неизменяемое значение с двумя десятками полей: длину даёт copyWith, а
   не вторая ответственность

packages/ez_data/lib/src/notifications/notification_service.dart      495
   один разговор с системой уведомлений. Два интерфейса, которые он реализует,
   — это два взгляда на один и тот же плагин и одну инициализацию; разделив
   класс, мы получим два объекта, спорящих за один плагин. Правила из него
   вынуты: когда график будит, решает shiftAlarmTimes в домене, что снять и
   что переставить у напоминаний записей — planReminders

packages/ez_data/lib/src/backup/backup_service.dart                   551
   один формат архива, прочитанный в обе стороны. Выгрузка и загрузка знают
   одну и ту же раскладку файлов, и разложить их по разным классам значит
   завести две копии этого знания


lib/src/features/memory_items/ui/widgets/time_reminder_sheet.dart     175
   одна форма: время, напоминание и звук. Разметка вынесена в свой виджет,
   осталось состояние и три обращения к системе

lib/src/features/memory_items/ui/memory_item_detail_screen.dart       239
   только сборка редактора: состояние, сценарии и поля из него вынуты, осталось
   связать их и запустить при открытии

lib/src/features/calendar/ui/calendar_screen.dart                     186
   одна страница месяца и её перелистывание; шапка, сетка и страницы вынуты

lib/src/app/app.dart                                                  190
   корень приложения: при запуске подключает уведомления, облако и трей Windows
```

## Сверх потолка, ещё не разобрано

Найдено 12 ноября 2026 сверкой размеров (Т12 аудита). Для каждого файла
вопрос из «Размерных потолков» ещё не задан: есть ли внутри вторая
ответственность. Если есть — резать по ней; если нет — перенести в раздел
выше с причиной. Часть файлов — правки интерфейса, которые на эту дату ещё
шли.

```text
lib/src/features/memory_items/ui/memory_editor_actions.dart          283
packages/ez_design/lib/src/components/page_turn/page_turn_geometry.dart 233
lib/src/features/calculator/ui/calculator_key_layouts.dart           199
packages/ez_design/lib/src/components/press_pulse.dart               186
lib/src/features/memory_items/ui/widgets/memory_sticker.dart         180
lib/src/features/security/ui/security_gate.dart                      174
lib/src/features/home_feed/ui/widgets/feed_day_rail.dart             172
lib/src/features/backup/ui/backup_actions.dart                       167
lib/src/features/memory_items/ui/widgets/memory_editor_menu.dart     160
lib/src/features/memory_items/ui/widgets/inline_time_field.dart      153
lib/src/features/memory_items/ui/widgets/payment_fields.dart         151
```
