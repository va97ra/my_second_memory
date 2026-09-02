import 'package:flutter/widgets.dart';
import 'russian_plural.dart';

class AppStrings {
  AppStrings(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('ru'), Locale('en')];

  static AppStrings of(BuildContext context) {
    return AppStrings(Localizations.localeOf(context));
  }

  bool get isRu => locale.languageCode == 'ru';

  String get appTitle => 'Ежедневник V2';
  String get feed => isRu ? 'Лента' : 'Feed';
  String get dayFeed => isRu ? 'Лента дня' : 'Day feed';
  String get dayTab => isRu ? 'День' : 'Day';
  String get notesTabShort => isRu ? 'Зап.' : 'Notes';
  String get monthlyRecurring => isRu ? 'Каждый месяц' : 'Every month';
  String get yearlyRecurring => isRu ? 'Каждый год' : 'Every year';
  String get feedFilter => isRu ? 'Фильтр' : 'Filter';
  String get previousPeriod => isRu ? 'Предыдущий период' : 'Previous period';
  String get nextPeriod => isRu ? 'Следующий период' : 'Next period';
  String get allFeatures => isRu ? 'Все возможности' : 'All features';
  String get backToToday => isRu ? 'Вернуться к сегодня' : 'Back to today';
  String get allRecords => isRu ? 'Все записи' : 'All records';
  String get activeRecords => isRu ? 'Активные' : 'Active';
  String get completedRecords => isRu ? 'Выполненные' : 'Done';
  String get today => isRu ? 'Сегодня' : 'Today';
  String get yesterday => isRu ? 'Вчера' : 'Yesterday';
  String recordsCount(int count) {
    if (!isRu) return count == 1 ? '1 record' : '$count records';
    return '$count ${russianPlural(count, 'запись', 'записи', 'записей')}';
  }

  String get previousMonth => isRu ? 'Предыдущий месяц' : 'Previous month';
  String get nextMonth => isRu ? 'Следующий месяц' : 'Next month';
  String get dayBeforeYesterdaySection =>
      isRu ? 'Это было позавчера' : 'This was two days ago';
  String get calendar => isRu ? 'Календарь' : 'Calendar';
  String get emptySlot => isRu ? 'Место свободно' : 'Free slot';
  String get emptySlotHint => isRu
      ? 'Инструмент, который здесь стоял, убран. Место в панели осталось под следующий.'
      : 'The tool that lived here is gone. The slot is kept for the next one.';
  String get toolSlotOne => isRu ? 'Слот 1' : 'Slot 1';
  String get toolSlotTwo => isRu ? 'Слот 2' : 'Slot 2';
  String get calculator => isRu ? 'Калькулятор' : 'Calculator';
  String get calculatorStandard => isRu ? 'Обычный' : 'Standard';
  String get calculatorScientific => isRu ? 'Инженерный' : 'Scientific';
  String get calculatorCopyResult =>
      isRu ? 'Копировать результат' : 'Copy result';
  String get calculatorIncomplete => '';
  String calculatorError(String code) => switch (code) {
        'divisionByZero' => isRu ? 'Деление на ноль' : 'Cannot divide by zero',
        'domain' => isRu ? 'Недопустимое значение' : 'Invalid value',
        'factorialTooLarge' =>
          isRu ? 'Слишком большой факториал' : 'Factorial is too large',
        _ => isRu ? 'Ошибка в выражении' : 'Invalid expression',
      };
  String get finance => isRu ? 'Финансы' : 'Finances';
  String get converter => isRu ? 'Конвертер' : 'Converter';
  String get engineering => isRu ? 'Инженерка' : 'Engineering';
  String get plumbing => isRu ? 'Сантехника' : 'Plumbing';
  String get savedCalculations =>
      isRu ? 'Сохранённые расчёты' : 'Saved calculations';
  String get saveCalculation => isRu ? 'Сохранить расчёт' : 'Save calculation';
  String get calculationName => isRu ? 'Название расчёта' : 'Calculation name';
  String get noSavedCalculations =>
      isRu ? 'Сохранённых расчётов пока нет' : 'No saved calculations yet';
  String get result => isRu ? 'Результат' : 'Result';
  String get from => isRu ? 'Из' : 'From';
  String get to => isRu ? 'В' : 'To';
  String get value => isRu ? 'Значение' : 'Value';
  String get source => isRu ? 'Источник' : 'Source';
  String get scope => isRu ? 'Область применения' : 'Scope';
  String get invalidNumber =>
      isRu ? 'Введите корректное число' : 'Enter a valid number';
  String get example => isRu ? 'Пример' : 'Example';

  // Величины конвертера: по одному слову на величину, и это слово живёт
  // здесь, а не в таблице единиц.
  String get length => isRu ? 'Длина' : 'Length';
  String get area => isRu ? 'Площадь' : 'Area';
  String get volume => isRu ? 'Объём' : 'Volume';
  String get mass => isRu ? 'Масса' : 'Mass';
  String get temperature => isRu ? 'Температура' : 'Temperature';
  String get pressure => isRu ? 'Давление' : 'Pressure';
  String get speed => isRu ? 'Скорость' : 'Speed';
  String get flow => isRu ? 'Расход' : 'Flow';
  String get power => isRu ? 'Мощность' : 'Power';
  String get energy => isRu ? 'Энергия' : 'Energy';
  String get dataSize => isRu ? 'Объём данных' : 'Data size';
  String get resistance => isRu ? 'Сопротивление' : 'Resistance';
  String get frequency => isRu ? 'Частота' : 'Frequency';
  String get angle => isRu ? 'Угол' : 'Angle';
  String get torque => isRu ? 'Момент силы' : 'Torque';
  String get density => isRu ? 'Плотность' : 'Density';

  String get voltage => isRu ? 'Напряжение' : 'Voltage';
  String get current => isRu ? 'Ток' : 'Current';

  String get fall => isRu ? 'Перепад' : 'Fall';

  String get width => isRu ? 'Ширина' : 'Width';
  String get height => isRu ? 'Высота' : 'Height';
  String get incomeAndExpenses =>
      isRu ? 'Доходы и расходы' : 'Income and expenses';
  String get income => isRu ? 'Доход' : 'Income';
  String get expenses => isRu ? 'Расходы' : 'Expenses';
  String get expense => isRu ? 'Расход' : 'Expense';
  String get balance => isRu ? 'Остаток' : 'Balance';
  String get currency => isRu ? 'Валюта' : 'Currency';
  String get amount => isRu ? 'Сумма' : 'Amount';
  String get currencyConverter =>
      isRu ? 'Конвертер валют' : 'Currency converter';
  String get swapCurrencies => isRu ? 'Поменять местами' : 'Swap';
  String get syncWithSource =>
      isRu ? 'Синхронизировать с источником' : 'Sync with the source';
  String get exchangeRate => isRu ? 'Курс' : 'Rate';
  String ratesAsOf(String date) =>
      isRu ? 'Курс ЦБ РФ на $date' : 'Bank of Russia rate for $date';
  String get ratesNotLoaded => isRu
      ? 'Курсы ещё не загружены — нужен интернет'
      : 'Rates are not loaded yet — the internet is needed';
  String get category => isRu ? 'Категория' : 'Category';
  String get financeDescription => isRu ? 'Описание' : 'Description';
  String get operationDate => isRu ? 'Дата операции' : 'Operation date';
  String get editOperation => isRu ? 'Изменить операцию' : 'Edit operation';
  String get addIncome => isRu ? 'Добавить доход' : 'Add income';
  String get addExpense => isRu ? 'Добавить расход' : 'Add expense';
  String get deleteOperationQuestion =>
      isRu ? 'Удалить эту операцию?' : 'Delete this operation?';
  List<String> get defaultIncomeCategories => isRu
      ? const [
          'Зарплата',
          'Аванс',
          'Подработка',
          'Начальный остаток',
          'Подарок',
          'Возврат',
          'Продажа',
          'Проценты',
          'Другое'
        ]
      : const [
          'Salary',
          'Advance',
          'Side job',
          'Opening balance',
          'Gift',
          'Refund',
          'Sale',
          'Interest',
          'Other'
        ];
  List<String> get defaultExpenseCategories => isRu
      ? const [
          'Продукты',
          'Жильё',
          'Транспорт',
          'Здоровье',
          'Связь и интернет',
          'Одежда',
          'Образование',
          'Развлечения',
          'Подписки',
          'Подарки',
          'Налоги',
          'Другое'
        ]
      : const [
          'Groceries',
          'Housing',
          'Transport',
          'Health',
          'Phone and internet',
          'Clothing',
          'Education',
          'Entertainment',
          'Subscriptions',
          'Gifts',
          'Taxes',
          'Other'
        ];
  String get calendarTapHint => isRu
      ? 'Нажмите на число, чтобы открыть день. Свайп вбок — месяц, вверх или вниз — год.'
      : 'Tap a date to open the day. Swipe sideways for months, up or down for years.';
  String get accounts => isRu ? 'Аккаунты' : 'Accounts';
  String get addAccount => isRu ? 'Добавить аккаунт' : 'Add account';
  String get deleteAccountQuestion =>
      isRu ? 'Удалить этот аккаунт?' : 'Delete this account?';
  String get editAccount => isRu ? 'Редактировать аккаунт' : 'Edit account';
  String get serviceName => isRu ? 'Сервис' : 'Service';
  String get login => isRu ? 'Логин' : 'Login';
  String get password => isRu ? 'Пароль' : 'Password';
  String get email => 'Email';
  String get website => isRu ? 'Сайт' : 'Website';
  String get note => isRu ? 'Заметка' : 'Note';
  String get copyPassword => isRu ? 'Скопировать пароль' : 'Copy password';
  String get passwordCopied => isRu ? 'Пароль скопирован' : 'Password copied';
  String get add => isRu ? 'Добавить' : 'Add';
  String get addRecord => isRu ? 'Добавить запись' : 'Add record';
  String get newRecord => isRu ? 'Новая запись' : 'New record';
  String get notes => isRu ? 'Записки' : 'Notes';
  String get noteCard => isRu ? 'Записка' : 'Note';
  String get newNote => isRu ? 'Новая записка' : 'New note';
  String get editNote => isRu ? 'Редактировать записку' : 'Edit note';
  String get people => isRu ? 'Люди' : 'People';
  String get projects => isRu ? 'Проекты' : 'Projects';
  String get memoryArchive => isRu ? 'Архив памяти' : 'Memory archive';
  String get backup => isRu ? 'Резервная копия' : 'Backup';
  String get backupSubtitle =>
      isRu ? 'Сохранить или восстановить данные' : 'Save or restore data';
  String get synchronization => isRu ? 'Синхронизация' : 'Synchronization';
  String get synchronizationSubtitle => isRu
      ? 'Android и Windows · сквозное шифрование'
      : 'Android and Windows · end-to-end encrypted';
  String get syncNotConfigured => isRu
      ? 'Облачная синхронизация ещё не подключена к проекту Supabase.'
      : 'Cloud synchronization is not connected to a Supabase project yet.';
  String get syncNotConfiguredHint => isRu
      ? 'Добавьте публичные SUPABASE_URL и SUPABASE_PUBLISHABLE_KEY при сборке приложения.'
      : 'Add the public SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY when building the app.';
  String get syncSignIn => isRu ? 'Войти' : 'Sign in';
  String get syncContinueWithGoogle =>
      isRu ? 'Продолжить с Google' : 'Continue with Google';
  String get syncVaultPassword =>
      isRu ? 'Пароль синхронизации' : 'Synchronization password';
  String get syncVaultPasswordHint => isRu
      ? 'Защищает общий ключ. Supabase его не получает.'
      : 'Protects the shared key. Supabase never receives it.';
  String get syncRepeatVaultPassword => isRu
      ? 'Повторите пароль синхронизации'
      : 'Repeat synchronization password';
  String get syncConnect => isRu ? 'Подключить' : 'Connect';
  String get syncNow => isRu ? 'Синхронизировать сейчас' : 'Sync now';
  String get syncSignOut => isRu ? 'Выйти из аккаунта' : 'Sign out';
  String get syncReady =>
      isRu ? 'Синхронизация включена' : 'Synchronization enabled';
  String get syncInProgress => isRu ? 'Синхронизация…' : 'Synchronizing…';
  String get syncNever => isRu ? 'Ещё не выполнялась' : 'Not synchronized yet';
  String get syncNewVault => isRu
      ? 'Создайте пароль синхронизации. Он может отличаться от PIN.'
      : 'Create a synchronization password. It may differ from your PIN.';
  String get syncExistingVault => isRu
      ? 'Введите пароль синхронизации, созданный на другом устройстве.'
      : 'Enter the synchronization password created on another device.';
  String get syncRecoveryCode =>
      isRu ? 'Аварийный код восстановления' : 'Emergency recovery code';
  String get syncUseRecoveryCode =>
      isRu ? 'Использовать аварийный код' : 'Use recovery code';
  String get syncUsePassword => isRu ? 'Использовать пароль' : 'Use password';
  String get syncRecoveryWarning => isRu
      ? 'Сохраните этот код вне приложения. Он показывается только при создании хранилища.'
      : 'Save this code outside the app. It is shown only when the vault is created.';

  String syncErrorMessage(String rawError) {
    final error = rawError.toLowerCase();
    if (error.contains('invalid login credentials') ||
        error.contains('invalid_credentials')) {
      return isRu
          ? 'Неверный email или пароль.'
          : 'Incorrect email or password.';
    }
    if (error.contains('email not confirmed') ||
        error.contains('email_not_confirmed')) {
      return isRu
          ? 'Сначала подтвердите адрес по ссылке в письме.'
          : 'Confirm the address using the link in the email first.';
    }
    if (error.contains('incorrect synchronization password')) {
      return isRu
          ? 'Неверный пароль синхронизации. Нужен пароль, созданный на первом устройстве, а не PIN.'
          : 'Incorrect synchronization password. Use the password created on the first device, not the PIN.';
    }
    if (error.contains('user already registered') ||
        error.contains('user_already_exists')) {
      return isRu
          ? 'Аккаунт уже существует. Переключитесь на вход.'
          : 'The account already exists. Switch to sign in.';
    }
    if (error.contains('email address not authorized') ||
        error.contains('email_address_not_authorized')) {
      return isRu
          ? 'Отправка писем для этого адреса пока не настроена. Используйте Google-вход.'
          : 'Email delivery is not configured for this address yet. Use Google sign-in.';
    }
    if (error.contains('rate limit') ||
        error.contains('over_email_send_rate_limit') ||
        error.contains('after 60 seconds')) {
      return isRu
          ? 'Слишком много запросов. Подождите минуту и попробуйте снова.'
          : 'Too many requests. Wait a minute and try again.';
    }
    if (error.contains('socketexception') ||
        error.contains('failed host lookup') ||
        error.contains('network')) {
      return isRu
          ? 'Нет соединения с сервером. Проверьте интернет.'
          : 'Could not reach the server. Check your connection.';
    }
    return isRu
        ? 'Не удалось выполнить операцию. Попробуйте ещё раз.'
        : 'The operation could not be completed. Try again.';
  }

  String get exportBackup =>
      isRu ? 'Сохранить резервную копию' : 'Export backup';
  String get importBackup => isRu ? 'Восстановить из копии' : 'Import backup';
  String get backupCreated =>
      isRu ? 'Резервная копия сохранена' : 'Backup saved';
  String get backupDownloadsHint => isRu
      ? 'Архив будет сохранён в папку Загрузки.'
      : 'The archive will be saved to Downloads.';
  String get backupSavedToDownloads =>
      isRu ? 'Архив сохранён в папку Загрузки' : 'Archive saved to Downloads';
  String get backupRestored =>
      isRu ? 'Резервная копия восстановлена' : 'Backup restored';
  String get backupPassword =>
      isRu ? 'Пароль резервной копии' : 'Backup password';
  String get repeatBackupPassword =>
      isRu ? 'Повторите пароль' : 'Repeat password';
  String get backupPasswordsDoNotMatch =>
      isRu ? 'Пароли не совпадают' : 'Passwords do not match';
  String get createBackupPassword =>
      isRu ? 'Придумайте пароль для архива' : 'Create backup password';
  String get enterBackupPassword =>
      isRu ? 'Введите пароль архива' : 'Enter backup password';
  String get backupPasswordHint => isRu
      ? 'Этот пароль понадобится для восстановления'
      : 'This password is required to restore';
  String get restoreBackupQuestion =>
      isRu ? 'Восстановить резервную копию?' : 'Restore backup?';
  String get restoreBackupWarning => isRu
      ? 'Текущие записи, графики смен и аккаунты будут заменены данными из файла.'
      : 'Current records, shift schedules, and accounts will be replaced by the file data.';
  String get invalidBackupFile =>
      isRu ? 'Не удалось прочитать резервную копию' : 'Cannot read backup file';
  String get invalidBackupPassword =>
      isRu ? 'Неверный пароль резервной копии' : 'Incorrect backup password';
  String get backupRestoreFailed => isRu
      ? 'Не удалось восстановить данные. Текущие данные сохранены.'
      : 'Could not restore data. Current data was preserved.';
  String get backupCreateFailed =>
      isRu ? 'Не удалось создать резервную копию' : 'Could not create backup';
  String get showPassword => isRu ? 'Показать пароль' : 'Show password';
  String get hidePassword => isRu ? 'Скрыть пароль' : 'Hide password';
  String get archive => isRu ? 'Архив' : 'Archive';
  String get archiveRecord => isRu ? 'Скрыть в архив' : 'Archive record';
  String get restoreToFeed => isRu ? 'Вернуть в ленту' : 'Restore to feed';
  String get settings => isRu ? 'Настройки' : 'Settings';
  String get title => isRu ? 'Название' : 'Title';
  String get recordType => isRu ? 'Тип записи' : 'Record type';
  String get description => isRu ? 'Запись' : 'Record';
  String get date => isRu ? 'Дата' : 'Date';
  String get time => isRu ? 'Время' : 'Time';
  String get timeNotSet => isRu ? 'Без времени' : 'No time';
  String get timeAndReminder =>
      isRu ? 'Время и напоминание' : 'Time and reminder';
  String get soundNotification =>
      isRu ? 'Звуковое уведомление' : 'Sound notification';
  String get systemAlarmSound =>
      isRu ? 'Системная мелодия' : 'System alarm sound';
  String get chooseSound => isRu ? 'Выбрать мелодию' : 'Choose sound';
  String get soundPickerUnavailable => isRu
      ? 'Не удалось открыть выбор мелодии. Будет использован системный звук.'
      : 'Cannot open the sound picker. The system sound will be used.';
  String get useSystemSound => isRu ? 'Системный звук' : 'Use system sound';
  String get reminderPermissionRequired => isRu
      ? 'Разрешите уведомления и точные события в настройках Android.'
      : 'Allow notifications and exact alarms in Android settings.';
  String get reminderFutureRequired => isRu
      ? 'Для напоминания выберите будущее время.'
      : 'Choose a future time for the reminder.';
  String get androidOnlyReminder => isRu
      ? 'Звуковые напоминания доступны на Android.'
      : 'Sound reminders are available on Android.';
  String get ready => isRu ? 'Готово' : 'Done';
  String get save => isRu ? 'Сохранить' : 'Save';
  String get saved => isRu ? 'Сохранено' : 'Saved';
  String get voice => isRu ? 'Голос' : 'Voice';
  String get stopRecording => isRu ? 'Остановить' : 'Stop';
  String get play => isRu ? 'Воспроизвести' : 'Play';
  String get delete => isRu ? 'Удалить' : 'Delete';
  String get cancel => isRu ? 'Отмена' : 'Cancel';
  String get completed => isRu ? 'Выполнено' : 'Done';
  String get markDone => isRu ? 'Отметить выполненным' : 'Mark done';
  String get markActive => isRu ? 'Вернуть в работу' : 'Mark active';
  String get editRecord => isRu ? 'Редактировать запись' : 'Edit record';
  String get recordNotFound => isRu ? 'Запись не найдена' : 'Record not found';
  String get deleteRecordQuestion =>
      isRu ? 'Удалить эту запись?' : 'Delete this record?';
  String get addImage => isRu ? 'Добавить фото' : 'Add image';
  String get gallery => isRu ? 'Галерея' : 'Gallery';
  String get camera => isRu ? 'Камера' : 'Camera';
  String get saving => isRu ? 'Сохраняю' : 'Saving';
  String get saveFailed => isRu ? 'Ошибка сохранения' : 'Save failed';
  String get loadFailed => isRu ? 'Не удалось загрузить данные' : 'Load failed';
  String get dayRecords => isRu ? 'Записи дня' : 'Day records';
  String get photo => isRu ? 'Фото' : 'Photo';
  String get voiceMessage => isRu ? 'Голосовое сообщение' : 'Voice message';
  String get recordingNow => isRu ? 'Идёт запись' : 'Recording';
  String get pinSecurity => isRu ? 'PIN и биометрия' : 'PIN and biometrics';
  String get shiftSchedules => isRu ? 'Графики смен' : 'Shift schedules';
  String get addShiftSchedule => isRu ? 'Добавить график' : 'Add schedule';
  String get editShiftSchedule =>
      isRu ? 'Редактировать график' : 'Edit schedule';
  String get organization => isRu ? 'Организация' : 'Organization';
  String get startDate => isRu ? 'Дата начала' : 'Start date';
  String get workDays => isRu ? 'Рабочих дней' : 'Work days';
  String get restDays => isRu ? 'Выходных дней' : 'Rest days';
  String get customSchedule => isRu ? 'Свой' : 'Custom';
  String get manualSchedule => isRu ? 'Настроить вручную' : 'Set manually';
  String get mainSettings => isRu ? 'Основное' : 'Main';
  String get scheduleSettings => isRu ? 'График' : 'Schedule';
  String get scheduleColor => isRu ? 'Цвет' : 'Color';
  String get reminders => isRu ? 'Напоминания' : 'Reminders';
  String get vacations => isRu ? 'Отпуска' : 'Vacations';
  String get vacation => isRu ? 'Отпуск' : 'Vacation';
  String get addVacation => isRu ? 'Добавить отпуск' : 'Add vacation';
  String get noVacations => isRu
      ? 'Отпуска для этого графика не указаны'
      : 'No vacations for this schedule';
  String get vacationStartDate =>
      isRu ? 'Первый день отпуска' : 'First vacation day';
  String get vacationDuration =>
      isRu ? 'Количество календарных дней' : 'Calendar days';
  String get vacationInvalidDuration => isRu
      ? 'Укажите количество дней больше нуля'
      : 'Enter a number of days greater than zero';
  String get vacationOverlap => isRu
      ? 'Этот период пересекается с другим отпуском'
      : 'This period overlaps another vacation';
  String vacationDays(int count) => isRu ? '$count дн.' : '$count days';
  String moreVacations(int count) => isRu ? 'ещё $count' : '$count more';
  String shiftAlarmNumber(int number) =>
      isRu ? 'Будильник $number' : 'Alarm $number';
  String get nextDayShiftAlarm =>
      isRu ? 'Будильник 2 · после смены' : 'Alarm 2 · after shift';

  /// Время будильника, который звонит на следующий день после смены.
  String nextDayAlarmAt(String time) => isRu ? '+1 д. $time' : '+1 d. $time';
  String get systemMelody => isRu ? 'Системная мелодия' : 'System melody';
  String get chooseAudioFile =>
      isRu ? 'Выбрать аудиофайл' : 'Choose audio file';
  String get chooseAudioFileSubtitle =>
      isRu ? 'Открыть проводник телефона' : 'Open the device file browser';
  String get shiftAlarmSubtitle => isRu
      ? 'Сработает в начале каждого рабочего дня'
      : 'Rings at the start of every work day';
  String get nextDayShiftAlarmSubtitle => isRu
      ? 'Сработает утром следующего дня после суточной смены'
      : 'Rings the next morning after a 24-hour shift';
  String get enabled => isRu ? 'Включен' : 'Enabled';
  String get disabled => isRu ? 'Выключен' : 'Disabled';
  String get noShiftSchedules =>
      isRu ? 'Графиков пока нет' : 'No schedules yet';
  String get deleteShiftScheduleQuestion =>
      isRu ? 'Удалить этот график?' : 'Delete this schedule?';
  String get workingToday => isRu ? 'Рабочий день' : 'Workday';
  String get language => isRu ? 'Язык' : 'Language';
  String get appearance => isRu ? 'Оформление' : 'Appearance';
  String get lightTheme => isRu ? 'Светлая тема' : 'Light theme';
  String get darkTheme => isRu ? 'Тёмная тема' : 'Dark theme';
  String get unlock => isRu ? 'Открыть' : 'Unlock';
  String get setupPinTitle =>
      isRu ? 'Создайте PIN для защиты данных' : 'Create a PIN to protect data';
  String get setupPinSubtitle => isRu
      ? 'PIN будет шифровать записи, аккаунты и настройки.'
      : 'PIN encrypts records, accounts, and settings.';
  String get createPin => isRu ? 'Создать PIN' : 'Create PIN';
  String get enableBiometricsQuestion =>
      isRu ? 'Включить вход по биометрии?' : 'Enable biometric unlock?';
  String get maybeLater => isRu ? 'Позже' : 'Later';
  String get unlockWithPin => isRu ? 'Войти по PIN' : 'Unlock with PIN';
  String get tryBiometricsAgain =>
      isRu ? 'Повторить биометрию' : 'Try biometrics again';
  String get biometrics => isRu ? 'Биометрия' : 'Biometrics';
  String get pinStatus => isRu ? 'PIN' : 'PIN';
  String get enablePin => isRu ? 'Включить PIN' : 'Enable PIN';
  String get changePin => isRu ? 'Сменить PIN' : 'Change PIN';
  String get disablePin => isRu ? 'Отключить PIN' : 'Disable PIN';
  String get currentPin => isRu ? 'Текущий PIN' : 'Current PIN';
  String get pinDisabled => isRu ? 'PIN отключен' : 'PIN disabled';
  String get disablePinWarning => isRu
      ? 'Данные будут расшифрованы и останутся доступными без PIN.'
      : 'Data will be decrypted and remain available without PIN.';
  String get biometricsSubtitle => isRu
      ? 'Показывать вход по биометрии на стартовом экране'
      : 'Show biometric unlock on the startup screen';
  String get biometricsNeedsPin =>
      isRu ? 'Сначала включите PIN' : 'Enable PIN first';
  String get wrongPin => isRu ? 'Неверный PIN' : 'Wrong PIN';
  String get biometricsUnavailable =>
      isRu ? 'Биометрия недоступна' : 'Biometrics unavailable';
  String get biometricsOk => isRu ? 'Биометрия подтверждена' : 'Biometrics ok';
  String get secureStorageStartFailed => isRu
      ? 'Не удалось запустить защищённое хранилище'
      : 'Could not start secure storage';
  String get secureStorageStartFailedSubtitle => isRu
      ? 'Данные остаются защищёнными. Попробуйте запустить приложение ещё раз.'
      : 'Your data remains protected. Try starting the app again.';
  String get retry => isRu ? 'Повторить' : 'Retry';
  String get closeApp => isRu ? 'Закрыть приложение' : 'Close app';
  String get trayOpen => isRu ? 'Открыть' : 'Open';
  String get trayLock => isRu ? 'Заблокировать' : 'Lock';
  String get trayExit => isRu ? 'Выйти' : 'Exit';
  String get launchWithWindows =>
      isRu ? 'Запускать вместе с Windows' : 'Launch with Windows';
  String get launchWithWindowsSubtitle => isRu
      ? 'Показывать окно входа после входа в систему'
      : 'Show the unlock window after signing in';
  String get launchWithWindowsFailed => isRu
      ? 'Не удалось изменить автозапуск Windows'
      : 'Could not update Windows startup';
  String get pinSaved => isRu ? 'PIN сохранен' : 'PIN saved';
}
