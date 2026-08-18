# Архитектура

## Структура

- `core` — маршрутизация, локализация, темы и общая инфраструктура;
- `shared` — переиспользуемые UI-компоненты;
- `features/*/domain` — модели и чистые правила;
- `features/*/data` — репозитории, шифрование и платформенные сервисы;
- `features/*/state` — Riverpod-провайдеры и контроллеры;
- `features/*/ui` — экраны и feature-local виджеты;
- `data/database` — Drift-схема и SQLite-адаптеры;
- `data/local_storage` — композиция локальных репозиториев и их lifecycle.

## Локальное хранилище

`localStorageScopeProvider` создаёт один `LocalStorageScope` на корневой
Riverpod-контейнер. На IO scope владеет одним `AppDatabase` и предоставляет:

- `SqliteMemoryRepository`;
- `SqliteRecurrenceRepository`;
- `SqliteRecurrenceExceptionRepository`;
- отдельный `DriftSecureEntityBackend`.

Репозитории не закрывают общую БД самостоятельно. `LocalStorageScope.close()`
идемпотентен и закрывает её при dispose контейнера. На Web scope предоставляет
SharedPreferences-реализации и `null` вместо SQLite backend.

`SqliteMemoryRepository` отвечает только за обычные записи. Операции таблицы
`secure_entities` изолированы в `DriftSecureEntityBackend`; зашифрованные
репозитории получают backend явно и не определяют его через type cast другого
репозитория.

SQLite-схема и ключи SharedPreferences не изменены, поэтому отдельная миграция
данных для этой композиции не требуется.

## Состояние и потоки данных

Контроллеры получают репозитории и side-effect сервисы через Riverpod:

```text
UI -> controller/provider -> repository/service -> local storage/platform
```

`MemoryItemsController` сериализует записи через `SequentialTaskQueue`, чтобы
старая операция не перезаписала новую. Автосохранение редактора использует тот
же принцип через `MemoryEditorSaveCoordinator`.

Повторы разделены на providers/selectors, контроллер серий и контроллер
исключений. Будущие экземпляры проецируются на лету; в БД сохраняются шаблоны,
история и изменённые/пропущенные даты.

Синхронизация разделена на состояние, provider-композицию и `SyncController`.
`AppSyncEngine` синхронизирует записи, аккаунты, графики смен, серии и исключения
повторов. Tombstones предотвращают восстановление удалённых данных офлайн-
устройством.

## Шифрование

- локальный PIN и ключ sync-vault независимы;
- AES-GCM payload хранится в отдельных secure rows;
- медиа при включённом PIN хранится в зашифрованных файлах;
- миграция сначала создаёт и проверяет защищённые копии, затем удаляет открытые;
- отключение PIN выполняет обратную проверяемую миграцию;
- Supabase получает только зашифрованные payload, метаданные версий и tombstones.

## UI и навигация

Основные вкладки используют `StatefulShellRoute.indexedStack`. Внутренние
экраны открываются через `GoRouter`, а переходы выбираются общей функцией
`pageTurnPage`.

Большие feature-local UI-библиотеки разделены на части по назначению, но их
приватные виджеты не расширяют публичный API. Геометрия строится от доступных
constraints и проверяется на 320/360/600/840 px и увеличенном тексте.

## Совместимость

Без отдельной миграции нельзя менять:

- поля и JSON `MemoryItem`, повторов, аккаунтов и графиков смен;
- SQLite schemaVersion и существующие таблицы;
- ключи SharedPreferences и secure storage;
- формат резервной копии и sync payload;
- семантику маршрутов и Android application ID редакций.
