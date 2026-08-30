# Ежедневник V2

Local-first Flutter-приложение для личных записей, календаря, задач, фото,
голосовых заметок, аккаунтов, графиков смен, напоминаний и повторов. Верхняя
панель добавляет к этому быстрые инструменты: калькулятор, финансы, конвертер
величин, инженерные расчёты и техсправочник. В финансах есть конвертер валют
по курсам Банка России.

Перед изменениями прочитайте:

- [`00_READ_THIS_FIRST.md`](00_READ_THIS_FIRST.md) — стабильные продуктовые
  правила;
- [`docs/architecture.md`](docs/architecture.md) — устройство кода и данных;
- [`docs/behavior.md`](docs/behavior.md) — что происходит с записью после
  действия человека;
- [`docs/recurrence.md`](docs/recurrence.md) — модель повторов и её инвариант;
- [`docs/sync_setup.md`](docs/sync_setup.md) — настройка зашифрованной
  синхронизации;
- [`docs/debt.md`](docs/debt.md) — чем код сегодня расходится с картой;
- [`docs/pending.md`](docs/pending.md) — о чём договорились, но ещё не сделали.

## Платформы

- Android: одна поставка `com.va97ra.ezhednevnikv2` с синхронизацией;
- Windows desktop с tray-режимом и single-instance поведением;
- Web с локальным SharedPreferences-хранилищем;
- SQLite-репозитории также подготовлены для остальных IO-платформ Flutter.

## Запуск

```powershell
flutter pub get
flutter run
```

В репозитории может использоваться локальный SDK `.tools/flutter`. Для
воспроизводимой проверки в текущей Windows-среде:

```powershell
$env:PUB_CACHE=(Resolve-Path '.tools\pub-cache').Path
$env:APPDATA=(Resolve-Path '.tools\appdata').Path
$env:LOCALAPPDATA=(Resolve-Path '.tools\localappdata').Path
$env:FLUTTER_SUPPRESS_ANALYTICS='true'
& '.\.tools\flutter\bin\flutter.bat' analyze
& '.\.tools\flutter\bin\flutter.bat' test
```

## Архитектурные ориентиры

- четыре пакета (`ez_domain`, `ez_data`, `ez_design`, `ez_core`) и
  приложение поверх них, где каждая фича делится на `state` и `ui`;
- Riverpod управляет состоянием и временем жизни локального хранилища;
- UI зависит от контрактов репозиториев, а не от конкретной SQLite/Web
  реализации;
- локальные изменения записываются последовательно;
- синхронизация шифрует данные до отправки в Supabase;
- существующие локальные данные и резервные копии считаются совместимым API.
