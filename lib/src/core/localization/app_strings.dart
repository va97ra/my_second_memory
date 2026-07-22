import 'package:flutter/widgets.dart';

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
  String get feedFilter => isRu ? 'Фильтр' : 'Filter';
  String get allRecords => isRu ? 'Все записи' : 'All records';
  String get activeRecords => isRu ? 'Активные' : 'Active';
  String get completedRecords => isRu ? 'Выполненные' : 'Done';
  String get today => isRu ? 'Сегодня' : 'Today';
  String get previousMonth => isRu ? 'Предыдущий месяц' : 'Previous month';
  String get nextMonth => isRu ? 'Следующий месяц' : 'Next month';
  String get yesterdaySection => isRu ? 'Это было вчера' : 'This was yesterday';
  String get dayBeforeYesterdaySection =>
      isRu ? 'Это было позавчера' : 'This was two days ago';
  String get calendar => isRu ? 'Календарь' : 'Calendar';
  String get calendarTapHint => isRu
      ? 'Нажмите на нужное число, чтобы открыть день и добавить запись.'
      : 'Tap a date to open the day and add a record.';
  String get accounts => isRu ? 'Аккаунты' : 'Accounts';
  String get addAccount => isRu ? 'Добавить аккаунт' : 'Add account';
  String get editAccount => isRu ? 'Редактировать аккаунт' : 'Edit account';
  String get serviceName => isRu ? 'Сервис' : 'Service';
  String get login => isRu ? 'Логин' : 'Login';
  String get password => isRu ? 'Пароль' : 'Password';
  String get email => 'Email';
  String get website => isRu ? 'Сайт' : 'Website';
  String get note => isRu ? 'Заметка' : 'Note';
  String get copyPassword => isRu ? 'Скопировать пароль' : 'Copy password';
  String get passwordCopied => isRu ? 'Пароль скопирован' : 'Password copied';
  String get noAccounts => isRu ? 'Аккаунтов пока нет' : 'No accounts yet';
  String get add => isRu ? 'Добавить' : 'Add';
  String get addRecord => isRu ? 'Добавить запись' : 'Add record';
  String get newRecord => isRu ? 'Новая запись' : 'New record';
  String get people => isRu ? 'Люди' : 'People';
  String get projects => isRu ? 'Проекты' : 'Projects';
  String get memoryBase => isRu ? 'База памяти' : 'Memory base';
  String get backup => isRu ? 'Резервная копия' : 'Backup';
  String get backupSubtitle =>
      isRu ? 'Сохранить или восстановить данные' : 'Save or restore data';
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
  String get archive => isRu ? 'Архив' : 'Archive';
  String get archiveRecord => isRu ? 'Скрыть в архив' : 'Archive record';
  String get restoreToFeed => isRu ? 'Вернуть в ленту' : 'Restore to feed';
  String get emptyArchive =>
      isRu ? 'В архиве пока ничего нет' : 'Archive is empty';
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
  String get requiredDate => isRu ? 'Дата обязательна' : 'Date is required';
  String get emptyFeed =>
      isRu ? 'На этот день пока ничего нет' : 'Nothing for this day yet';
  String get noRecords => isRu ? 'Записей нет' : 'No records';
  String get voice => isRu ? 'Голос' : 'Voice';
  String get startRecording => isRu ? 'Начать запись' : 'Start recording';
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
  String get messageHint => isRu ? 'Сообщение' : 'Message';
  String get photo => isRu ? 'Фото' : 'Photo';
  String get voiceMessage => isRu ? 'Голосовое сообщение' : 'Voice message';
  String get recordingNow => isRu ? 'Идёт запись' : 'Recording';
  String get noMessagesForDay =>
      isRu ? 'За этот день пока ничего нет' : 'No messages for this day yet';
  String get pinSecurity => isRu ? 'PIN и биометрия' : 'PIN and biometrics';
  String get shiftSchedules => isRu ? 'Графики смен' : 'Shift schedules';
  String get addShiftSchedule => isRu ? 'Добавить график' : 'Add schedule';
  String get editShiftSchedule =>
      isRu ? 'Редактировать график' : 'Edit schedule';
  String get organization => isRu ? 'Организация' : 'Organization';
  String get startDate => isRu ? 'Дата начала' : 'Start date';
  String get workDays => isRu ? 'Рабочих дней' : 'Work days';
  String get restDays => isRu ? 'Выходных дней' : 'Rest days';
  String get schedulePreset => isRu ? 'Шаблон' : 'Pattern';
  String get customSchedule => isRu ? 'Свой' : 'Custom';
  String get manualSchedule => isRu ? 'Настроить вручную' : 'Set manually';
  String get mainSettings => isRu ? 'Основное' : 'Main';
  String get scheduleSettings => isRu ? 'График' : 'Schedule';
  String get scheduleColor => isRu ? 'Цвет' : 'Color';
  String get reminders => isRu ? 'Напоминания' : 'Reminders';
  String shiftAlarmNumber(int number) =>
      isRu ? 'Будильник $number' : 'Alarm $number';
  String get nextDayShiftAlarm =>
      isRu ? 'Будильник 2 · после смены' : 'Alarm 2 · after shift';
  String get shiftAlarm => isRu ? 'Будильник смены' : 'Shift alarm';
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
  String get notebookTheme => isRu ? 'Тема «Блокнот»' : 'Notebook theme';
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
  String get pinSaved => isRu ? 'PIN сохранен' : 'PIN saved';
  String get recordAudioBeforeSaving => isRu
      ? 'Сначала запишите голосовую заметку'
      : 'Record audio before saving';
}
