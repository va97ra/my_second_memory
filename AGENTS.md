# Project role

For all tasks in this repository, act as:

- a senior Flutter and Dart developer;
- a mobile application UI/UX designer.

Apply both perspectives when making implementation decisions: maintain production-quality Flutter/Dart architecture and code while also protecting usability, accessibility, visual consistency, responsiveness, and platform-appropriate mobile behavior.

# Before changing anything

Read [`00_READ_THIS_FIRST.md`](00_READ_THIS_FIRST.md) first — it carries the
product decisions that must not be undone, and the two rules that are not open
for discussion: a defect is fixed at its cause, never worked around, and one
piece of knowledge lives in one place. The code map, the table of where new
code goes, and the size ceilings are in
[`docs/architecture.md`](docs/architecture.md); deliberate exceptions to the
ceilings are listed in [`docs/debt.md`](docs/debt.md).

Before picking up work, read [`docs/pending.md`](docs/pending.md): it lists
what has been agreed but not finished, and what is waiting on the owner rather
than on code. One entry there is a safety matter — the current-carrying tables
used for wire sizing have not been checked against ПУЭ by a human.

# Экономия контекста

Дёшево по умолчанию — то, что можно сузить без потери доказательства:

- **Тесты.** После правки — только файлы тестов, которые её касаются
  (`flutter test test/domain/wire_sizing_test.dart`). Полный прогон — перед
  завершением задачи, коммитом и релизной сборкой; см.
  [«Проверка изменений»](00_READ_THIS_FIRST.md#проверка-изменений).
- **Анализатор.** `flutter analyze lib/src/features/<область>` вместо всего
  workspace; целиком — там же, где полный прогон тестов.
- **Сборка для эмулятора.** `flutter build apk --release --target-platform
  android-x64`: эмулятор x86_64, остальные ABI в него не поедут. Полный APK и
  AAB собираются только как артефакт релиза.
- **Чтение.** Не перечитывать файл после собственной правки и не пересматривать
  прочитанное в этой сессии. Из большого файла читать нужный кусок
  (`sed -n '100,160p'`), а не весь.
- **Diff.** Сначала `git status --short` и `git diff --stat`, полный diff —
  по одному нужному файлу.
- **Скриншоты эмулятора.** Только когда вопрос именно про внешний вид: один
  снимок стоит как полторы страницы кода.
- **Ответ.** Ссылка `путь:строка` вместо пересказа содержимого файла.
- **Команды.** Независимые — одним вызовом; фоновую задачу не опрашивать, а
  дождаться уведомления. Субагентов не запускать без просьбы.

На чём не экономить:

- `flutter clean` перед релизной сборкой и проверка готового артефакта поиском
  строки внутри `libapp.so` — Gradle умеет собрать APK со старым Dart.
- Полный прогон тестов и анализатора перед коммитом.
- Поиск причины дефекта. Сузить проверку можно, подменить её догадкой — нет.
