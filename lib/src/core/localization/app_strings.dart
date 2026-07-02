import 'package:flutter/widgets.dart';

class AppStrings {
  AppStrings(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('ru'), Locale('en')];

  static AppStrings of(BuildContext context) {
    return AppStrings(Localizations.localeOf(context));
  }

  bool get isRu => locale.languageCode == 'ru';

  String get appTitle => isRu ? 'Моя вторая память' : 'My Second Memory';
  String get feed => isRu ? 'Лента' : 'Feed';
  String get dayFeed => isRu ? 'Лента дня' : 'Day feed';
  String get today => isRu ? 'Сегодня' : 'Today';
  String get yesterdaySection => isRu ? 'Это было вчера' : 'This was yesterday';
  String get dayBeforeYesterdaySection =>
      isRu ? 'Это было позавчера' : 'This was two days ago';
  String get calendar => isRu ? 'Календарь' : 'Calendar';
  String get add => isRu ? 'Добавить' : 'Add';
  String get people => isRu ? 'Люди' : 'People';
  String get projects => isRu ? 'Проекты' : 'Projects';
  String get memoryBase => isRu ? 'База памяти' : 'Memory base';
  String get settings => isRu ? 'Настройки' : 'Settings';
  String get title => isRu ? 'Название' : 'Title';
  String get recordType => isRu ? 'Тип записи' : 'Record type';
  String get description => isRu ? 'Запись' : 'Record';
  String get date => isRu ? 'Дата' : 'Date';
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
  String get enabled => isRu ? 'Включен' : 'Enabled';
  String get noShiftSchedules =>
      isRu ? 'Графиков пока нет' : 'No schedules yet';
  String get deleteShiftScheduleQuestion =>
      isRu ? 'Удалить этот график?' : 'Delete this schedule?';
  String get workingToday => isRu ? 'Рабочий день' : 'Workday';
  String get language => isRu ? 'Язык' : 'Language';
  String get unlock => isRu ? 'Открыть' : 'Unlock';
  String get biometrics => isRu ? 'Биометрия' : 'Biometrics';
  String get wrongPin => isRu ? 'Неверный PIN' : 'Wrong PIN';
  String get biometricsUnavailable =>
      isRu ? 'Биометрия недоступна' : 'Biometrics unavailable';
  String get biometricsOk => isRu ? 'Биометрия подтверждена' : 'Biometrics ok';
  String get pinSaved => isRu ? 'PIN сохранен' : 'PIN saved';
  String get recordAudioBeforeSaving => isRu
      ? 'Сначала запишите голосовую заметку'
      : 'Record audio before saving';
}
