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
  String get today => isRu ? 'Сегодня' : 'Today';
  String get calendar => isRu ? 'Календарь' : 'Calendar';
  String get add => isRu ? 'Добавить' : 'Add';
  String get people => isRu ? 'Люди' : 'People';
  String get projects => isRu ? 'Проекты' : 'Projects';
  String get memoryBase => isRu ? 'База памяти' : 'Memory base';
  String get settings => isRu ? 'Настройки' : 'Settings';
  String get title => isRu ? 'Название' : 'Title';
  String get description => isRu ? 'Описание' : 'Description';
  String get date => isRu ? 'Дата' : 'Date';
  String get save => isRu ? 'Сохранить' : 'Save';
  String get requiredDate => isRu ? 'Дата обязательна' : 'Date is required';
  String get emptyFeed =>
      isRu ? 'На этот день пока ничего нет' : 'Nothing for this day yet';
  String get voice => isRu ? 'Голос' : 'Voice';
  String get startRecording => isRu ? 'Начать запись' : 'Start recording';
  String get stopRecording => isRu ? 'Остановить' : 'Stop';
  String get play => isRu ? 'Воспроизвести' : 'Play';
  String get pinSecurity => isRu ? 'PIN и биометрия' : 'PIN and biometrics';
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
